extends Control
## Sala de espera: lista de jogadores e configurações da partida (só o host edita).

@onready var player_list: VBoxContainer = %PlayerList
@onready var map_option: OptionButton = %MapOption
@onready var mode_option: OptionButton = %ModeOption
@onready var prep_spin: SpinBox = %PrepSpin
@onready var hunt_spin: SpinBox = %HuntSpin
@onready var auto_time_check: CheckBox = %AutoTimeCheck
@onready var start_button: Button = %StartButton
@onready var vote_box: VBoxContainer = %VoteBox
@onready var vote_buttons: HBoxContainer = %VoteButtons
@onready var info_label: Label = %InfoLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for map_info in GameState.MAPS:
		map_option.add_item(map_info.name)
	map_option.add_item("Votação dos jogadores")
	# Os itens são chaves em português; a lista traduz sozinha ao exibir.
	for i in GameState.MAPS.size():
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(220, 64)
		button.tooltip_text = GameState.MAPS[i].description
		button.pressed.connect(GameState.vote_map.bind(i))
		vote_buttons.add_child(button)
	for mode_info in GameState.MODES:
		mode_option.add_item(mode_info.name)
	Network.players_changed.connect(_refresh)
	GameState.settings_changed.connect(_refresh)
	GameState.votes_changed.connect(_refresh)
	map_option.item_selected.connect(func(_i: int) -> void: _push_settings())
	mode_option.item_selected.connect(func(_i: int) -> void: _push_settings())
	prep_spin.value_changed.connect(func(_v: float) -> void: _push_settings())
	hunt_spin.value_changed.connect(func(_v: float) -> void: _push_settings())
	auto_time_check.toggled.connect(func(_on: bool) -> void: _push_settings())
	start_button.pressed.connect(GameState.start_game)
	%LeaveButton.pressed.connect(GameState.leave_to_menu)
	_refresh()


func _notification(what: int) -> void:
	# Botão Voltar do Android: sai da sala.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameState.leave_to_menu()


func _process(_delta: float) -> void:
	# Modo de teste: `--autostart=N` inicia sozinho quando N jogadores entrarem
	# (`--map=I` e `--mode=I` escolhem mapa (-1 = votação) e modo; `--prep=S` e `--hunt=S` ajustam os tempos).
	var wanted := int(Network.cmdline.get("autostart", "0"))
	if wanted > 0 and multiplayer.is_server() and Network.players.size() >= wanted:
		Network.cmdline.erase("autostart")
		var settings := GameState.settings.duplicate()
		settings.map = clampi(int(Network.cmdline.get("map", settings.map)), GameState.MAP_VOTE, GameState.MAPS.size() - 1)
		settings.mode = clampi(int(Network.cmdline.get("mode", settings.mode)), 0, GameState.MODES.size() - 1)
		settings.prep_time = int(Network.cmdline.get("prep", settings.prep_time))
		settings.hunt_time = int(Network.cmdline.get("hunt", settings.hunt_time))
		if Network.cmdline.has("prep") or Network.cmdline.has("hunt"):
			settings.auto_time = false
		GameState.set_settings(settings)
		GameState.start_game()


func _refresh() -> void:
	# Fora da árvore (trocando de cena) ou já desconectado (voltando ao menu).
	if not is_inside_tree() or not multiplayer.has_multiplayer_peer():
		return
	var is_host := multiplayer.is_server()
	for child in player_list.get_children():
		child.queue_free()
	for id: int in Network.players:
		var info: Dictionary = Network.players[id]
		var label := Label.new()
		# Nomes de jogadores não passam pela tradução (alguém pode se chamar "Casa").
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.text = "%s%s%s" % [info.name, tr("  (host)") if id == 1 else "", tr("  (você)") if id == multiplayer.get_unique_id() else ""]
		if GameState.is_map_vote() and GameState.votes.has(id):
			label.text += tr("  · vota %s") % tr(GameState.MAPS[GameState.votes[id]].name)
		label.modulate = info.color.lightened(0.2)
		label.add_theme_font_size_override("font_size", 20)
		player_list.add_child(label)

	var settings := GameState.settings
	var auto_time: bool = settings.get("auto_time", false)
	var controls: Array[Control] = [map_option, mode_option, prep_spin, hunt_spin, auto_time_check]
	for control in controls:
		control.set_block_signals(true)
	map_option.select(GameState.MAPS.size() if GameState.is_map_vote() else settings.map)
	mode_option.select(settings.mode)
	auto_time_check.button_pressed = auto_time
	auto_time_check.text = "Ligado" if auto_time else "Desligado"
	prep_spin.value = settings.prep_time
	hunt_spin.value = settings.hunt_time
	if auto_time and not GameState.is_map_vote():
		var times := GameState.suggested_times(settings.map, Network.players.size())
		prep_spin.value = times.x
		hunt_spin.value = times.y
	for control in controls:
		control.set_block_signals(false)

	map_option.disabled = not is_host
	mode_option.disabled = not is_host
	auto_time_check.disabled = not is_host
	prep_spin.editable = is_host and not auto_time
	hunt_spin.editable = is_host and not auto_time
	start_button.visible = is_host

	vote_box.visible = GameState.is_map_vote()
	var counts := GameState.count_votes()
	var my_vote: int = GameState.votes.get(multiplayer.get_unique_id(), -1)
	for i in vote_buttons.get_child_count():
		var button := vote_buttons.get_child(i) as Button
		button.text = "%s\n%s%s" % [tr(GameState.MAPS[i].name),
			tr("1 voto") if counts[i] == 1 else tr("%d votos") % counts[i], tr("  (seu voto)") if i == my_vote else ""]
		button.set_pressed_no_signal(i == my_vote)
		button.modulate = Color("ffd54f") if i == my_vote else Color.WHITE
	start_button.disabled = Network.players.size() < GameState.min_players()

	var mode_text: String = tr("Modo %s: %s") % [tr(GameState.MODES[settings.mode].name), tr(GameState.MODES[settings.mode].description)]
	if auto_time and GameState.is_map_vote():
		mode_text += "\n" + tr("Tempos automáticos: definidos pelo mapa vencedor e pelo número de jogadores.")
	if is_host:
		var addresses := Network.get_local_addresses()
		info_label.text = "%s\n%s\n%s\n%s" % [
			mode_text,
			tr("Seu IP na rede: %s (porta %d)") % [", ".join(addresses) if not addresses.is_empty() else tr("desconhecido"), Network.PORT],
			_web_text(addresses),
			_status_text(),
		]
	else:
		info_label.text = mode_text + "\n" + tr("Aguardando o host iniciar a partida...")


## Endereço para quem vai jogar pelo navegador (celular, tablet, outro PC).
func _web_text(addresses: PackedStringArray) -> String:
	if not WebHost.is_running():
		return tr("Versão para navegador indisponível nesta build.")
	var urls := PackedStringArray()
	for address in addresses:
		urls.append("http://%s:%d" % [address, WebHost.PORT])
	return tr("Celulares e navegadores: abram %s") % (", ".join(urls) if not urls.is_empty() else "http://<IP>:%d" % WebHost.PORT)


func _status_text() -> String:
	var count := Network.players.size()
	if count < GameState.min_players():
		return tr("Aguardando pelo menos %d jogadores...") % GameState.min_players()
	if count == 1:
		return tr("Modo de depuração: dá para iniciar sozinho e testar o mapa (F1–F6 na partida).")
	return tr("Pronto para começar!")


func _push_settings() -> void:
	GameState.set_settings({
		"map": GameState.MAP_VOTE if map_option.selected >= GameState.MAPS.size() else map_option.selected,
		"mode": mode_option.selected,
		"auto_time": auto_time_check.button_pressed,
		"prep_time": int(prep_spin.value),
		"hunt_time": int(hunt_spin.value),
	})
