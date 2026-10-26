extends Control
## Controles de toque da partida (só no modo toque):
## - analógico flutuante: o dedo que encosta na parte esquerda da tela vira o
##   centro do analógico, e arrastar aperta as ações move_* com a força certa;
## - arrastar em qualquer outro lugar gira a câmera (sinal InputMode.look);
## - botões redondos à direita apertam as ações do jogo (pular, virar, pegar...).
## Recebe os toques de todos os dedos aqui, então dá para andar, olhar e apertar
## um botão ao mesmo tempo. A HUD chama `update_context` a cada quadro.

const STICK_RADIUS := 70.0
const STICK_DEADZONE := 0.12
## Parte da tela (da esquerda) onde um toque vira o analógico.
const STICK_AREA := 0.42
## Centro e raio de cada botão, medidos a partir do canto inferior direito.
## "catch" e "transform" dividem o lugar: nunca aparecem juntos.
const BUTTONS := [
	{"action": "catch", "at": Vector2(125, 135), "radius": 64.0},
	{"action": "transform", "at": Vector2(125, 135), "radius": 64.0},
	{"action": "jump", "at": Vector2(255, 80), "radius": 46.0},
	{"action": "revert", "at": Vector2(95, 285), "radius": 40.0},
	{"action": "lock_rotation", "at": Vector2(215, 235), "radius": 40.0},
	{"action": "freeze", "at": Vector2(330, 185), "radius": 40.0},
]
## Os mesmos dados, medidos a partir do canto superior direito.
const TOP_BUTTONS := [
	{"action": "scoreboard", "at": Vector2(140, 48), "radius": 34.0},
	{"action": "pause", "at": Vector2(55, 48), "radius": 34.0},
]
const MOVE_ACTIONS := ["move_left", "move_right", "move_forward", "move_back"]

var _buttons := {}
## Índice do dedo -> botão apertado por ele.
var _button_touches := {}
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_vector := Vector2.ZERO
var _look_index := -1
var _margin := Vector4.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for spec: Dictionary in BUTTONS + TOP_BUTTONS:
		var button := TouchButton.new(spec.action, spec.radius)
		_buttons[spec.action] = button
		add_child(button)
	get_viewport().size_changed.connect(_layout)
	_layout()


## Mostra os botões que fazem sentido para o jogador local agora.
func update_context(player: Player, paused: bool) -> void:
	var show := InputMode.touch and not paused
	if not show:
		if visible:
			_release_all()
		visible = false
		return
	visible = true
	var flying := player == null or player.caught or DebugTools.free_camera
	var seeker := not flying and player.role == GameState.Role.SEEKER
	var hider := not flying and not seeker
	var disguised := hider and player.is_disguised()
	_show("catch", seeker)
	_show("transform", hider)
	_show("revert", disguised)
	_show("lock_rotation", disguised)
	_show("freeze", disguised or flying)
	_show("jump", true)
	_show("scoreboard", true)
	_show("pause", true)
	for action: String in _buttons:
		_buttons[action].set_text(InputMode.button_name(action))
	# Voando (assistindo ou pego), pular sobe e congelar desce.
	if flying:
		_buttons.jump.set_text(tr("SUBIR"))
		_buttons.freeze.set_text(tr("DESCER"))
	var aim := Color("2ecc71") if player and not flying and player.has_valid_aim() else Color.TRANSPARENT
	_buttons.catch.highlight = aim
	_buttons.transform.highlight = aim
	_buttons.lock_rotation.highlight = Color("f1c40f") if disguised and player.rotation_locked else Color.TRANSPARENT


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_start(event.index, event.position)
		else:
			_on_touch_end(event.index)
	elif event is InputEventScreenDrag:
		if event.index == _stick_index:
			_update_stick(event.position)
		elif event.index == _look_index:
			InputMode.look.emit(event.relative)


func _on_touch_start(index: int, point: Vector2) -> void:
	for action: String in _buttons:
		var button: TouchButton = _buttons[action]
		if button.hits(point):
			_button_touches[index] = button
			button.press()
			return
	var area := get_viewport_rect().size
	if _stick_index < 0 and point.x < area.x * STICK_AREA and point.y > area.y * 0.25:
		_stick_index = index
		_stick_origin = point
		_update_stick(point)
	elif _look_index < 0:
		_look_index = index


func _on_touch_end(index: int) -> void:
	if _button_touches.has(index):
		_button_touches[index].release()
		_button_touches.erase(index)
	elif index == _stick_index:
		_stick_index = -1
		_set_stick(Vector2.ZERO)
	elif index == _look_index:
		_look_index = -1


func _update_stick(point: Vector2) -> void:
	var offset := point - _stick_origin
	# O centro acompanha o dedo quando ele passa do limite, como nos jogos de celular.
	if offset.length() > STICK_RADIUS:
		_stick_origin = point - offset.limit_length(STICK_RADIUS)
		offset = point - _stick_origin
	_set_stick(offset / STICK_RADIUS)


func _set_stick(value: Vector2) -> void:
	_stick_vector = value if value.length() > STICK_DEADZONE else Vector2.ZERO
	var strengths := [maxf(-_stick_vector.x, 0.0), maxf(_stick_vector.x, 0.0),
		maxf(-_stick_vector.y, 0.0), maxf(_stick_vector.y, 0.0)]
	for i in MOVE_ACTIONS.size():
		if strengths[i] > 0.0:
			Input.action_press(MOVE_ACTIONS[i], strengths[i])
		else:
			Input.action_release(MOVE_ACTIONS[i])
	queue_redraw()


func _release_all() -> void:
	for button: TouchButton in _buttons.values():
		button.release()
	_button_touches.clear()
	_stick_index = -1
	_look_index = -1
	_set_stick(Vector2.ZERO)


func _show(action: String, value: bool) -> void:
	var button: TouchButton = _buttons[action]
	if not value and button.pressed:
		button.release()
		for index in _button_touches.keys():
			if _button_touches[index] == button:
				_button_touches.erase(index)
	button.visible = value


func _draw() -> void:
	var area := get_viewport_rect().size
	if _stick_index >= 0:
		draw_circle(_stick_origin, STICK_RADIUS, Color(0, 0, 0, 0.25))
		draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 3.0, true)
		draw_circle(_stick_origin + _stick_vector.limit_length(1.0) * STICK_RADIUS, STICK_RADIUS * 0.42, Color(1, 1, 1, 0.55))
	else:
		# Lembrete de onde fica o analógico enquanto ninguém encosta nele.
		var hint := Vector2(_margin.x + 150.0, area.y - _margin.w - 140.0)
		draw_arc(hint, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 3.0, true)
		draw_circle(hint, STICK_RADIUS * 0.42, Color(1, 1, 1, 0.2))


## Posiciona os botões respeitando a área segura da tela (entalhe, cantos).
func _layout() -> void:
	_margin = _safe_margins()
	var area := get_viewport_rect().size
	for spec: Dictionary in BUTTONS:
		_place(spec, Vector2(area.x - _margin.z - spec.at.x, area.y - _margin.w - spec.at.y))
	for spec: Dictionary in TOP_BUTTONS:
		_place(spec, Vector2(area.x - _margin.z - spec.at.x, _margin.y + spec.at.y))
	queue_redraw()


func _place(spec: Dictionary, center: Vector2) -> void:
	var button: TouchButton = _buttons[spec.action]
	button.position = center - Vector2.ONE * spec.radius


## Margens (esquerda, cima, direita, baixo) em unidades da interface.
func _safe_margins() -> Vector4:
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0 or safe.size.x <= 0 or not OS.has_feature("mobile"):
		return Vector4.ZERO
	var scale := get_viewport_rect().size.x / float(screen.x)
	return Vector4(safe.position.x, safe.position.y, screen.x - safe.end.x, screen.y - safe.end.y) * scale
