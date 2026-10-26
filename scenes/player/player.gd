class_name Player
extends CharacterBody3D
## Jogador em 3ª pessoa. O movimento é controlado pelo próprio dono (MoveSync);
## papel, captura e disfarce são decididos pelo servidor (StateSync).

const ALIEN_SIZE := Vector3(0.7, 1.7, 0.7)
## Forma de colisão do alien (mesmo formato de um disfarce de primitiva).
const ALIEN_BODY := {"shape": PropBuilder.Shape.CAPSULE, "size": ALIEN_SIZE, "color": Color.WHITE}
const GRAVITY := 16.0
const MOUSE_SENSITIVITY := 0.0025
const ALIEN_SPEED := 5.0
const SEEKER_SPEED := 6.0
const JUMP_VELOCITY := 6.0
const SPECTATOR_SPEED := 9.0
const FALL_LIMIT := -20.0
const CAMERA_DISTANCE := 4.0
## Altura da câmera na forma de alien: acima da cabeça (1,65 m com as antenas),
## para a mira no centro da tela não ficar atrás da própria cabeça.
const ALIEN_EYE_HEIGHT := 2.05
## Objetos com volume acima de HEAVY_VOLUME (m³) ficam mais lentos, até
## HEAVY_FACTOR da velocidade em HEAVIEST_VOLUME.
const HEAVY_VOLUME := 0.3
const HEAVIEST_VOLUME := 2.0
const HEAVY_FACTOR := 0.55

var peer_id := 1

# Estado replicado pelo servidor.
var display_name := "":
	set(value):
		display_name = value
		_update_visuals()
var body_color := Color.WHITE:
	set(value):
		body_color = value
		_update_visuals()
var role := GameState.Role.HIDER:
	set(value):
		role = value
		_update_visuals()
var caught := false:
	set(value):
		caught = value
		_update_visuals()
## Modo Infecção: escondido que foi pego e virou ajudante do procurador.
var infected := false:
	set(value):
		infected = value
		_update_visuals()
## Vazio = forma de alien. Caso contrário {"shape", "size", "color"} de um Prop.
var disguise := {}:
	set(value):
		disguise = value
		_update_visuals()

# Estado local de quem controla este jogador.
var rotation_locked := false
var cam_yaw := 0.0
var cam_pitch := -0.35
var _eye_height := ALIEN_EYE_HEIGHT
## Altura do centro do corpo atual (alien ou disfarce), usada no alcance da mira.
var _center_height := ALIEN_SIZE.y * 0.5
var _slow_until := 0.0
var _catch_ready_at := 0.0
var _disguise_ready_at := 0.0
## Formas de colisão do corpo ($Collision e as extras dos objetos compostos).
var _shape_nodes: Array = []
## Último disfarce mostrado, para animar só quando ele muda.
var _shown_disguise := {}
var _pop_tween: Tween

@onready var visual: Node3D = $Visual
@onready var alien: AlienModel = $Visual/Alien
@onready var disguise_mesh: MeshInstance3D = $Visual/DisguiseMesh
@onready var collision: CollisionShape3D = $Collision
@onready var camera_pivot: Node3D = $CameraPivot
@onready var pitch_pivot: Node3D = $CameraPivot/Pitch
@onready var spring_arm: SpringArm3D = $CameraPivot/Pitch/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/Pitch/SpringArm3D/Camera3D
@onready var aim_ray: RayCast3D = $CameraPivot/Pitch/SpringArm3D/Camera3D/AimRay
@onready var name_label: Label3D = $NameLabel
@onready var audio: AudioStreamPlayer3D = $Audio
@onready var move_sync: MultiplayerSynchronizer = $MoveSync
@onready var state_sync: MultiplayerSynchronizer = $StateSync


func _enter_tree() -> void:
	peer_id = name.to_int()
	set_multiplayer_authority(peer_id)
	$StateSync.set_multiplayer_authority(1)


func _ready() -> void:
	_shape_nodes = [collision]
	# O nome do jogador não passa pela tradução.
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var is_local := is_multiplayer_authority()
	camera.current = is_local
	camera_pivot.top_level = true
	spring_arm.add_excluded_object(get_rid())
	aim_ray.add_exception(self)
	if is_local:
		cam_yaw = rotation.y
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	move_sync.add_visibility_filter(_is_visible_to)
	state_sync.add_visibility_filter(_is_visible_to)
	_update_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and _has_input():
		cam_yaw -= event.relative.x * MOUSE_SENSITIVITY
		cam_pitch = clampf(cam_pitch - event.relative.y * MOUSE_SENSITIVITY, -1.3, 0.8)
		return
	if caught or not GameState.can_move() or not _has_input():
		return
	if event.is_action_pressed("transform"):
		_try_transform()
	elif event.is_action_pressed("revert"):
		_try_revert()
	elif event.is_action_pressed("lock_rotation") and is_disguised():
		rotation_locked = not rotation_locked
		GameState.notified.emit(tr("Rotação travada.") if rotation_locked else tr("Rotação livre."), GameState.COLOR_INFO)
	elif event.is_action_pressed("catch"):
		_try_catch()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if caught:
		_spectate(delta)
		return

	var active := GameState.can_move() and _has_input()
	var frozen := active and is_disguised() and Input.is_action_pressed("freeze")
	var input := Vector2.ZERO
	if active and not frozen:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Basis(Vector3.UP, cam_yaw) * Vector3(input.x, 0.0, input.y)
	var speed := _get_speed()
	var blend := minf(1.0, (12.0 if is_on_floor() else 3.0) * delta)
	velocity.x = lerpf(velocity.x, direction.x * speed, blend)
	velocity.z = lerpf(velocity.z, direction.z * speed, blend)
	if frozen:
		velocity.x = 0.0
		velocity.z = 0.0

	if is_on_floor():
		if active and not frozen and Input.is_action_just_pressed("jump"):
			velocity.y = _get_jump_velocity()
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	if is_disguised():
		if not rotation_locked and not frozen:
			rotation.y = cam_yaw
	elif direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, 12.0 * delta))

	if global_position.y < FALL_LIMIT and is_instance_valid(GameState.game):
		teleport(GameState.game.map.get_hider_spawns()[0])


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	var target := global_position + Vector3.UP * _eye_height
	camera_pivot.global_position = camera_pivot.global_position.lerp(target, minf(1.0, 20.0 * delta))
	camera_pivot.rotation = Vector3(0.0, cam_yaw, 0.0)
	pitch_pivot.rotation.x = cam_pitch


# --- API usada pelo GameState e pela HUD ---------------------------------------

func is_disguised() -> bool:
	return not disguise.is_empty()


func teleport(target: Vector3) -> void:
	global_position = target
	velocity = Vector3.ZERO
	camera_pivot.global_position = target + Vector3.UP * _eye_height


func apply_penalty(duration: float) -> void:
	_slow_until = _now() + duration
	block_catch(duration)
	_play(Sfx.miss())


func block_catch(duration: float) -> void:
	_catch_ready_at = maxf(_catch_ready_at, _now() + duration)


func play_whistle() -> void:
	_play(Sfx.whistle())


func refresh_visibility() -> void:
	move_sync.update_visibility()
	state_sync.update_visibility()


## Retorna true se a mira está sobre algo que pode ser usado agora
## (um objeto para copiar ou algo para tentar pegar).
func has_valid_aim() -> bool:
	if caught or not GameState.can_move():
		return false
	if role == GameState.Role.SEEKER:
		var target := _get_aimed(GameState.CATCH_RANGE)
		return target is Prop or target is Player
	return get_aimed_prop() != null


## Objeto que o escondido pode copiar agora (ou null).
func get_aimed_prop() -> Prop:
	if caught or role != GameState.Role.HIDER or not GameState.can_move():
		return null
	var prop := _get_aimed(GameState.TRANSFORM_RANGE) as Prop
	return prop if prop != null and prop.disguisable else null


func is_slowed() -> bool:
	return _now() < _slow_until


# --- Ações ---------------------------------------------------------------------

func _try_transform() -> void:
	if role != GameState.Role.HIDER or _now() < _disguise_ready_at:
		return
	var prop := _get_aimed(GameState.TRANSFORM_RANGE) as Prop
	if prop == null or not prop.disguisable:
		GameState.notified.emit(tr("Mire num objeto próximo para se transformar."), GameState.COLOR_INFO)
		return
	var new_disguise := prop.get_disguise()
	if disguise == new_disguise:
		return
	# Começa alinhado como o original (encostado na parede, por exemplo).
	var yaw := prop.global_rotation.y
	if not _fits(new_disguise, yaw):
		GameState.notified.emit(tr("Sem espaço para virar isso aqui."), GameState.COLOR_BAD)
		return
	_disguise_ready_at = _now() + GameState.DISGUISE_COOLDOWN
	GameState.request_disguise(prop)
	rotation.y = yaw
	rotation_locked = true
	_play(Sfx.poof())


func _try_revert() -> void:
	if not is_disguised():
		return
	if not _fits(ALIEN_BODY, rotation.y):
		GameState.notified.emit(tr("Sem espaço para voltar à forma de alien."), GameState.COLOR_BAD)
		return
	GameState.request_revert()
	_play(Sfx.poof())


func _try_catch() -> void:
	if role != GameState.Role.SEEKER or GameState.phase != GameState.Phase.HUNT:
		return
	if _now() < _catch_ready_at:
		return
	_catch_ready_at = _now() + 0.5
	var target := _get_aimed(GameState.CATCH_RANGE)
	if target is Player:
		GameState.request_catch(target.peer_id)
	elif target is Prop:
		GameState.request_catch(0)


# --- Auxiliares ------------------------------------------------------------------

func _get_aimed(max_distance: float) -> Node:
	aim_ray.force_raycast_update()
	if not aim_ray.is_colliding():
		return null
	var center := global_position + Vector3.UP * _center_height
	if center.distance_to(aim_ray.get_collision_point()) > max_distance:
		return null
	return aim_ray.get_collider() as Node


## Confere se a caixa envolvente do novo formato cabe aqui, girada em `yaw`.
func _fits(new_shape: Dictionary, yaw: float) -> bool:
	var bounds := PropBuilder.bounds_of(new_shape)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = PropBuilder.make_shape(PropBuilder.Shape.BOX, bounds.size)
	query.transform = Transform3D(Basis(Vector3.UP, yaw), global_position + Vector3.UP * 0.05) \
		* Transform3D(Basis.IDENTITY, bounds.get_center())
	query.collision_mask = 1 | 2 | 4
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _get_speed() -> float:
	var speed := ALIEN_SPEED
	if role == GameState.Role.SEEKER:
		speed = SEEKER_SPEED
	elif is_disguised():
		# Objetos pequenos andam devagar; os médios quase como o alien; os pesados devagar.
		var bounds := PropBuilder.bounds_of(disguise)
		speed = clampf(2.5 + bounds.size.y * 2.5, 2.5, ALIEN_SPEED) * _weight_factor(bounds)
	if is_slowed():
		speed *= 0.35
	return speed


func _get_jump_velocity() -> float:
	if is_disguised():
		var bounds := PropBuilder.bounds_of(disguise)
		return clampf(3.0 + bounds.size.y * 2.0, 3.0, JUMP_VELOCITY) * _weight_factor(bounds)
	return JUMP_VELOCITY


func _weight_factor(bounds: AABB) -> float:
	var volume := bounds.size.x * bounds.size.y * bounds.size.z
	return clampf(remap(volume, HEAVY_VOLUME, HEAVIEST_VOLUME, 1.0, HEAVY_FACTOR), HEAVY_FACTOR, 1.0)


func _spectate(delta: float) -> void:
	var input := Vector2.ZERO
	var vertical := 0.0
	if _has_input():
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		vertical = Input.get_action_strength("jump") - Input.get_action_strength("freeze")
	var direction := camera.global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * vertical
	global_position += direction.limit_length(1.0) * SPECTATOR_SPEED * delta


func _has_input() -> bool:
	# Com a câmera livre de depuração (F2), o mouse e o teclado movem só a câmera.
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not DebugTools.free_camera


func _is_visible_to(peer: int) -> bool:
	return GameState.is_peer_loaded(peer)


func _update_visuals() -> void:
	if not is_node_ready():
		return
	var body := disguise if is_disguised() else ALIEN_BODY
	if is_disguised():
		PropBuilder.apply_mesh(disguise_mesh, disguise)
	else:
		rotation_locked = false
	PropBuilder.apply_shapes(self, _shape_nodes, body)
	for node: CollisionShape3D in _shape_nodes:
		node.disabled = caught
	var bounds := PropBuilder.bounds_of(body)
	visual.visible = not caught
	alien.visible = not is_disguised()
	disguise_mesh.visible = is_disguised()
	alien.setup(body_color, role == GameState.Role.SEEKER, infected)
	if disguise != _shown_disguise:
		_shown_disguise = disguise
		_pop()
	name_label.text = display_name
	name_label.modulate = body_color.lightened(0.3)
	name_label.visible = not caught and not is_disguised() and not is_multiplayer_authority()
	# Câmera mais alta e mais longe para objetos grandes (não fica dentro do guarda-roupa).
	var extent := maxf(bounds.size.x, bounds.size.z)
	_center_height = bounds.get_center().y
	if is_disguised():
		_eye_height = clampf(minf(bounds.size.y + 0.3, maxf(1.6, bounds.size.y - 0.1)), 0.9, 2.3)
	else:
		_eye_height = ALIEN_EYE_HEIGHT
	spring_arm.spring_length = CAMERA_DISTANCE + maxf(0.0, extent - 1.0) * 0.8


## Efeito de gosma ao virar objeto ou voltar a ser alien: achata e estica de volta.
func _pop() -> void:
	if _pop_tween:
		_pop_tween.kill()
	alien.reset_motion()
	visual.scale = Vector3(1.35, 0.25, 1.35)
	_pop_tween = create_tween()
	_pop_tween.tween_property(visual, "scale", Vector3(0.85, 1.2, 0.85), 0.1)
	_pop_tween.tween_property(visual, "scale", Vector3.ONE, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _play(stream: AudioStream) -> void:
	audio.stream = stream
	audio.play()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
