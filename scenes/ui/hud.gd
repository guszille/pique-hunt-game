extends CanvasLayer
## Interface da partida: fase e cronômetro, papel do jogador, mira, sorteio,
## tela escura do procurador, avisos, placar (Tab) e menu de pausa (Esc).

const PHASE_NAMES := {
	GameState.Phase.LOADING: "CARREGANDO",
	GameState.Phase.DRAW: "SORTEIO",
	GameState.Phase.PREP: "PREPARAÇÃO",
	GameState.Phase.HUNT: "CAÇADA",
	GameState.Phase.END: "FIM DA RODADA",
}
const TOAST_TIME := 4.0

var _last_tick := -1
## Nome do objeto mirado pelo escondido, logo abaixo da mira.
var _aim_label: Label
var _debug_label: Label
## Contador de FPS (só em builds de depuração, para medir no celular).
var _fps_label: Label
## O mouse estava capturado no último quadro (navegador: Esc solta o ponteiro).
var _had_capture := false

@onready var phase_label: Label = %PhaseLabel
@onready var info_label: Label = %InfoLabel
@onready var role_label: Label = %RoleLabel
@onready var crosshair: Label = %Crosshair
@onready var big_label: Label = %BigLabel
@onready var blind: ColorRect = %Blind
@onready var blind_label: Label = %BlindLabel
@onready var hints_label: Label = %HintsLabel
@onready var toasts: VBoxContainer = %Toasts
@onready var scoreboard: PanelContainer = %Scoreboard
@onready var score_list: VBoxContainer = %ScoreList
@onready var pause_menu: PanelContainer = %PauseMenu
@onready var lobby_button: Button = %LobbyButton
@onready var ui_audio: AudioStreamPlayer = %UiAudio
@onready var touch_controls: Control = %TouchControls


func _ready() -> void:
	Language.changed.connect(_rebuild_scoreboard)
	GameState.notified.connect(_on_notified)
	GameState.phase_changed.connect(_on_phase_changed)
	Network.players_changed.connect(_rebuild_scoreboard)
	%ResumeButton.pressed.connect(_set_paused.bind(false))
	lobby_button.pressed.connect(GameState.return_to_lobby)
	%QuitButton.pressed.connect(GameState.leave_to_menu)
	lobby_button.visible = multiplayer.is_server()
	pause_menu.visible = false
	_rebuild_scoreboard()
	_add_aim_label()
	if DebugTools.enabled:
		_add_debug_label()
		_add_fps_label()
	InputMode.changed.connect(_apply_input_mode)
	_apply_input_mode()
	if WebPage.can_fullscreen():
		var fullscreen := Button.new()
		fullscreen.text = tr("Tela cheia")
		fullscreen.custom_minimum_size = Vector2(0, 40)
		fullscreen.pressed.connect(WebPage.toggle_fullscreen)
		%QuitButton.get_parent().add_child(fullscreen)
		%QuitButton.get_parent().move_child(fullscreen, %QuitButton.get_index())


func _notification(what: int) -> void:
	# Botão Voltar do Android: abre e fecha o menu de pausa.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_set_paused(not pause_menu.visible)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not pause_menu.visible)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and not pause_menu.visible \
			and not InputMode.touch and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var player: Player = GameState.game.get_local_player() if is_instance_valid(GameState.game) else null
	var phase := GameState.phase
	var seconds := ceili(GameState.time_left)

	phase_label.text = "%s  %d:%02d%s" % [tr(PHASE_NAMES.get(phase, "")), seconds / 60, seconds % 60,
		tr("  (pausado)") if GameState.timer_paused else ""]
	var hiders := GameState.count_hiders()
	info_label.text = tr("Escondidos livres: %d / %d") % [hiders.x, hiders.y] if hiders.y > 0 else ""

	_update_role(player)
	_update_big_label(player)

	# Só o procurador sorteado fica cego (quem virou procurador pelo F1 não).
	var is_blind := player != null and player.peer_id == GameState.seeker_id and phase == GameState.Phase.PREP
	blind.visible = is_blind
	if is_blind:
		blind_label.text = tr("Você é o procurador!\nContando até os outros se esconderem...") + "\n\n%d" % seconds

	crosshair.visible = player != null and not player.caught and not DebugTools.free_camera
	if crosshair.visible:
		crosshair.modulate = Color("2ecc71") if player.has_valid_aim() else Color(1, 1, 1, 0.7)
	var aimed: Prop = player.get_aimed_prop() if crosshair.visible else null
	_aim_label.visible = aimed != null
	if aimed:
		_aim_label.text = (tr("Virar %s") if InputMode.touch else tr("[E] Virar %s")) % aimed.get_label()

	touch_controls.update_context(player, pause_menu.visible)
	_check_pointer_lock()
	if _fps_label:
		_fps_label.text = "%d FPS" % Engine.get_frames_per_second()

	scoreboard.visible = Input.is_action_pressed("scoreboard") or phase == GameState.Phase.END

	if phase == GameState.Phase.PREP and seconds <= 5 and seconds != _last_tick:
		_last_tick = seconds
		_play(Sfx.tick())


## Papel do jogador e dicas de comando. No toque, as dicas são curtas e citam
## os botões da tela (os nomes vêm de InputMode.button_name).
func _update_role(player: Player) -> void:
	var touch := InputMode.touch
	if DebugTools.free_camera:
		role_label.text = tr("CÂMERA LIVRE")
		role_label.modulate = Color("f1c40f")
		hints_label.text = tr("Use o analógico para voar e arraste para olhar.") if touch \
			else tr("WASD + mouse para voar  |  [Espaço] sobe  |  [Shift] desce  |  [F2] voltar ao jogador")
		return
	if player == null:
		role_label.text = tr("ASSISTINDO")
		role_label.modulate = Color("bdc3c7")
		hints_label.text = tr("Você entra na próxima rodada. Use o analógico para voar e arraste para olhar.") if touch \
			else tr("Você entra na próxima rodada.  WASD + mouse para voar  |  [Tab] Placar")
		return
	if player.role == GameState.Role.SEEKER:
		var title := tr("AJUDANTE DO PROCURADOR") if player.infected else tr("PROCURADOR")
		role_label.text = title + (tr("  (lento!)") if player.is_slowed() else "")
		role_label.modulate = Color("8bc34a") if player.infected else Color("e74c3c")
		hints_label.text = tr("Chegue perto, mire e toque em %s. Errar num objeto deixa você lento.") % InputMode.button_name("catch") \
			if touch else tr("[Clique] Pegar (de perto)  |  Errar num objeto deixa você lento  |  [Tab] Placar")
	elif player.caught:
		role_label.text = tr("PEGO!")
		role_label.modulate = Color("95a5a6")
		hints_label.text = tr("Você foi pego. Use o analógico para voar e arraste para olhar.") if touch \
			else tr("Você foi pego. Voe e assista: WASD, [Espaço] sobe, [Shift] desce  |  [Tab] Placar")
	elif player.is_disguised():
		role_label.text = tr("ESCONDIDO (disfarçado)")
		role_label.modulate = Color("2ecc71")
		var rotation_state := tr("TRAVADA") if player.rotation_locked else tr("livre")
		hints_label.text = tr("Rotação: %s  |  Segure %s para ficar imóvel") % [rotation_state, InputMode.button_name("freeze")] \
			if touch else tr("[E] Trocar de objeto  |  [Q] Voltar a ser alien  |  [R] Rotação: %s  |  [Shift] Congelar") % rotation_state
	else:
		role_label.text = tr("ESCONDIDO")
		role_label.modulate = Color("2ecc71")
		hints_label.text = tr("Mire num objeto e toque em %s para virar ele.") % InputMode.button_name("transform") \
			if touch else tr("Mire num objeto e aperte [E] para virar ele  |  [Espaço] Pular  |  [Tab] Placar")


func _update_big_label(player: Player) -> void:
	match GameState.phase:
		GameState.Phase.LOADING:
			big_label.text = tr("Esperando todos carregarem...")
		GameState.Phase.DRAW:
			big_label.text = _roulette_text()
		GameState.Phase.PREP:
			if player and player.role == GameState.Role.HIDER and GameState.time_left > GameState.settings.prep_time - 4:
				big_label.text = tr("Corra e se esconda!")
			else:
				big_label.text = ""
		GameState.Phase.END:
			big_label.text = Language.format(GameState.result_message)
		_:
			big_label.text = ""


func _roulette_text() -> String:
	var names := GameState.round_peers.map(func(id: int) -> String: return Network.get_player_name(id))
	if names.is_empty():
		return ""
	var elapsed := GameState.DRAW_TIME - GameState.time_left
	if GameState.time_left < 1.3:
		var mode: Dictionary = GameState.MODES[GameState.settings.get("mode", 0)]
		return tr("%s vai procurar!\nModo %s: %s") % [Network.get_player_name(GameState.seeker_id), tr(mode.name), tr(mode.description)]
	# A roleta gira rápido e vai desacelerando.
	var index := int(pow(elapsed, 0.6) * 9.0) % names.size()
	return tr("Sorteando quem procura...") + "\n" + names[index]


func _on_phase_changed(phase: GameState.Phase) -> void:
	_last_tick = -1
	match phase:
		GameState.Phase.HUNT:
			_play(Sfx.whistle())
		GameState.Phase.END:
			_rebuild_scoreboard()


func _on_notified(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	toasts.add_child(label)
	var tween := label.create_tween()
	tween.tween_interval(TOAST_TIME)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _rebuild_scoreboard() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	for child in score_list.get_children():
		child.queue_free()
	var ids := Network.players.keys()
	ids.sort_custom(func(a: int, b: int) -> bool: return Network.players[a].score > Network.players[b].score)
	for id: int in ids:
		var info: Dictionary = Network.players[id]
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		name_label.text = info.name + (tr("  (você)") if id == multiplayer.get_unique_id() else "")
		name_label.modulate = info.color.lightened(0.3)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var score_label := Label.new()
		score_label.text = tr("%d pts") % info.score
		row.add_child(name_label)
		row.add_child(score_label)
		score_list.add_child(row)


func _add_aim_label() -> void:
	_aim_label = Label.new()
	_aim_label.add_theme_font_size_override("font_size", 16)
	_aim_label.add_theme_constant_override("outline_size", 5)
	_aim_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_aim_label.modulate = Color("c8f7c5")
	_aim_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_aim_label.offset_left = -200.0
	_aim_label.offset_right = 200.0
	_aim_label.offset_top = 22.0
	_aim_label.offset_bottom = 46.0
	_aim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aim_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aim_label)
	move_child(_aim_label, crosshair.get_index() + 1)


func _add_fps_label() -> void:
	_fps_label = Label.new()
	_fps_label.position = Vector2(20, 46)
	_fps_label.modulate = Color(1, 0.85, 0.3, 0.85)
	_fps_label.add_theme_font_size_override("font_size", 14)
	_fps_label.add_theme_constant_override("outline_size", 5)
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fps_label)


func _add_debug_label() -> void:
	var label := Label.new()
	_debug_label = label
	label.text = tr(DebugTools.HELP)
	label.modulate = Color(1, 0.85, 0.3, 0.85)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -70.0
	label.offset_bottom = -48.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	move_child(label, hints_label.get_index() + 1)


## No toque, as dicas vão para o alto da tela (embaixo ficam o analógico e os
## botões), os avisos ficam mais curtos e as teclas F de depuração somem.
func _apply_input_mode() -> void:
	var touch := InputMode.touch
	if touch:
		# Coluna estreita embaixo do papel, quebrando linha, longe do cronômetro.
		hints_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		hints_label.anchor_right = 0.36
		hints_label.offset_top = 72.0
		hints_label.offset_bottom = 140.0
		hints_label.offset_right = 0.0
		hints_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		hints_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hints_label.offset_top = -44.0
		hints_label.offset_bottom = -14.0
		hints_label.offset_right = -20.0
		hints_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hints_label.offset_left = 20.0
	toasts.offset_top = 110.0 if touch else 90.0
	toasts.offset_bottom = 280.0 if touch else 400.0
	if _debug_label:
		_debug_label.visible = not touch
	if not touch and not pause_menu.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## No navegador, o Esc é do próprio navegador: ele solta o ponteiro e a tecla não
## chega ao jogo. Quando o ponteiro é solto no meio da partida, abre a pausa.
func _check_pointer_lock() -> void:
	if not WebPage.is_web() or InputMode.touch:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _had_capture and not captured and not pause_menu.visible:
		_set_paused(true)
	_had_capture = captured


func _set_paused(paused: bool) -> void:
	pause_menu.visible = paused
	if not InputMode.touch:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


func _play(stream: AudioStream) -> void:
	if WebAudio.enabled:
		WebAudio.play(stream)
		return
	ui_audio.stream = stream
	ui_audio.play()
