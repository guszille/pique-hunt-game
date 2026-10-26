extends Node
## Ferramentas de depuração. Só funcionam em builds de depuração (rodando pelo
## editor ou por `godot --path .`); as builds exportadas com tools/export.sh não
## têm. Para testar as regras normais numa build de depuração, use `-- --no-debug`.
##
## Nessas builds o host pode iniciar a partida sozinho e, durante a partida:
##   F1  troca entre escondido e procurador
##   F2  liga/desliga a câmera livre
##   F3  mostra/esconde as colisões
##   F4  pula para a próxima fase
##   F5  troca para o próximo mapa
##   F6  pausa/retoma o cronômetro
## F1, F4, F5 e F6 são pedidos ao host; F2 e F3 valem só para quem apertou.

const HELP := "DEPURAÇÃO  [F1] Papel  [F2] Câmera livre  [F3] Colisões  [F4] Pular fase  [F5] Próximo mapa  [F6] Pausar tempo"
const OVERLAY_REFRESH := 0.3
## Cor das colisões por camada: mundo, objetos e jogadores.
const LAYER_COLORS := {1: Color("4dd9ff"), 2: Color("ff9933"), 4: Color("ff4de6")}

var enabled := false
var free_camera := false
var show_collisions := false

var _refresh_timer := 0.0
var _csg_overlays := {}
var _materials := {}


func _ready() -> void:
	enabled = OS.is_debug_build() and not Network.cmdline.has("no-debug")
	set_process(enabled)
	set_process_unhandled_input(enabled)
	if enabled:
		print("Ferramentas de depuração ativas (F1–F6 na partida).")


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _in_game():
		return
	match key.physical_keycode:
		KEY_F1:
			GameState.request_debug(GameState.DebugAction.TOGGLE_ROLE)
		KEY_F2:
			_toggle_free_camera()
		KEY_F3:
			_toggle_collisions()
		KEY_F4:
			GameState.request_debug(GameState.DebugAction.SKIP_PHASE)
		KEY_F5:
			GameState.request_debug(GameState.DebugAction.NEXT_MAP)
		KEY_F6:
			GameState.request_debug(GameState.DebugAction.TOGGLE_PAUSE)
		_:
			return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if GameState.phase == GameState.Phase.LOBBY:
		free_camera = false
	if not show_collisions or not is_instance_valid(GameState.game):
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = OVERLAY_REFRESH
		_update_overlays(GameState.game)


func _in_game() -> bool:
	return is_instance_valid(GameState.game) and multiplayer.has_multiplayer_peer()


func _toggle_free_camera() -> void:
	free_camera = not free_camera
	if free_camera:
		# Começa de onde a câmera atual está olhando.
		var current := get_viewport().get_camera_3d()
		if current:
			GameState.game.spectator_camera.global_transform = current.global_transform
	GameState.notified.emit(
		"Câmera livre: WASD + mouse, [Espaço] sobe, [Shift] desce." if free_camera else "Câmera livre desligada.",
		GameState.COLOR_INFO)


func _toggle_collisions() -> void:
	show_collisions = not show_collisions
	_refresh_timer = 0.0
	if not show_collisions:
		for node in get_tree().get_nodes_in_group(&"debug_collision"):
			node.queue_free()
		_csg_overlays.clear()
	GameState.notified.emit(
		"Colisões visíveis: azul = mundo, laranja = objetos, rosa = jogadores." if show_collisions else "Colisões escondidas.",
		GameState.COLOR_INFO)


## Desenha a forma de colisão de cada CollisionShape3D e de cada CSG com colisão.
## Roda de tempos em tempos para acompanhar disfarces e jogadores novos.
func _update_overlays(root: Node) -> void:
	for node in root.find_children("*", "CollisionShape3D", true, false):
		var shape_node := node as CollisionShape3D
		var overlay := shape_node.get_node_or_null(^"DebugShape") as MeshInstance3D
		if overlay == null:
			overlay = _make_overlay(shape_node.get_parent())
			overlay.name = "DebugShape"
			shape_node.add_child(overlay)
		if not overlay.has_meta(&"shape") or overlay.get_meta(&"shape") != shape_node.shape:
			overlay.set_meta(&"shape", shape_node.shape)
			_set_overlay_mesh(overlay, shape_node.shape.get_debug_mesh() if shape_node.shape else null)
		overlay.visible = not shape_node.disabled

	for key in _csg_overlays.keys():
		if not is_instance_valid(key):
			_csg_overlays.erase(key)
	for node in root.find_children("*", "CSGShape3D", true, false):
		var csg := node as CSGShape3D
		if _csg_overlays.has(csg) or not csg.is_root_shape() or not csg.use_collision:
			continue
		# Fica fora do CSG para não forçar o CSG a se reconstruir.
		var overlay := _make_overlay(csg)
		var shape := csg.bake_collision_shape()
		_set_overlay_mesh(overlay, shape.get_debug_mesh() if shape else null)
		root.add_child(overlay)
		overlay.global_transform = csg.global_transform
		_csg_overlays[csg] = overlay


func _make_overlay(owner_body: Node) -> MeshInstance3D:
	var overlay := MeshInstance3D.new()
	overlay.add_to_group(&"debug_collision")
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var layer := 1
	if owner_body is CollisionObject3D:
		layer = owner_body.collision_layer
	elif owner_body is CSGShape3D:
		layer = owner_body.collision_layer
	overlay.set_meta(&"color", LAYER_COLORS.get(layer, Color.WHITE))
	return overlay


## Linhas na cor da camada. As faces (quando o Godot gera) ficam quase
## transparentes nos objetos e jogadores, e invisíveis no mundo, para não tingir
## o mapa inteiro.
func _set_overlay_mesh(overlay: MeshInstance3D, mesh: Mesh) -> void:
	overlay.mesh = mesh
	if mesh == null:
		return
	var color: Color = overlay.get_meta(&"color")
	var fill := Color(color, 0.0 if color == LAYER_COLORS[1] else 0.18)
	for i in mesh.get_surface_count():
		var is_lines: bool = mesh.surface_get_primitive_type(i) in [Mesh.PRIMITIVE_LINES, Mesh.PRIMITIVE_LINE_STRIP]
		overlay.set_surface_override_material(i, _material(color if is_lines else fill))


func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[color] = material
	return _materials[color]
