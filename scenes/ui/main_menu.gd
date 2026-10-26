extends Control
## Menu inicial: nome do jogador, IP do host e botões Hospedar / Entrar.

@onready var name_edit: LineEdit = %NameEdit
@onready var ip_edit: LineEdit = %IpEdit
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	%QuitButton.pressed.connect(get_tree().quit)
	# Em celular, sair é pelo sistema (botão Voltar ou trocar de app); no navegador, fechando a aba.
	%QuitButton.visible = not InputMode.handheld and not WebPage.is_web()
	if WebPage.is_web():
		_setup_web()
	Network.connection_succeeded.connect(_on_connected)
	Network.connection_failed.connect(_on_connection_failed)
	Network.connection_rejected.connect(_on_connection_rejected)
	Language.changed.connect(_update_version_label)
	_update_version_label()
	if Network.local_name != "Jogador":
		name_edit.text = Network.local_name
	status_label.text = GameState.menu_message
	GameState.menu_message = ""
	_apply_cmdline.call_deferred()


## No navegador não dá para hospedar: a página veio do host, então o IP já é o dele.
func _setup_web() -> void:
	host_button.visible = false
	$Scroll/Center/Panel/VBox/Separator.visible = false
	var host := WebPage.host_name()
	if host != "" and host != "localhost":
		ip_edit.text = host
	var index := join_button.get_index() + 1
	if WebPage.can_fullscreen():
		var fullscreen := Button.new()
		fullscreen.text = tr("Tela cheia")
		fullscreen.custom_minimum_size = Vector2(0, 36)
		fullscreen.pressed.connect(WebPage.toggle_fullscreen)
		join_button.get_parent().add_child(fullscreen)
		join_button.get_parent().move_child(fullscreen, index)
	elif WebPage.is_ios():
		var tip := Label.new()
		tip.text = tr("Dica: para jogar em tela cheia, toque em Compartilhar e depois em Adicionar à Tela de Início.")
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.custom_minimum_size = Vector2(356, 0)
		tip.add_theme_font_size_override("font_size", 13)
		join_button.get_parent().add_child(tip)
		join_button.get_parent().move_child(tip, index)


func _notification(what: int) -> void:
	# Botão Voltar do Android: no menu principal, fecha o jogo.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()


func _update_version_label() -> void:
	%VersionLabel.text = tr("versão %s") % Network.version \
		+ (tr("  ·  depuração: hospede e inicie sozinho para testar") if DebugTools.enabled else "")


func _on_host_pressed() -> void:
	var err := Network.host_game(_player_name())
	if err != OK:
		status_label.text = tr("Não foi possível hospedar na porta %d (erro %d).") % [Network.PORT, err]
		return
	get_tree().change_scene_to_file(GameState.LOBBY_SCENE)


func _on_join_pressed() -> void:
	var address := ip_edit.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var err := Network.join_game(address, _player_name())
	if err != OK:
		status_label.text = tr("Endereço inválido (erro %d).") % err
		return
	status_label.text = tr("Conectando a %s...") % address
	_set_buttons_enabled(false)


func _on_connected() -> void:
	get_tree().change_scene_to_file(GameState.LOBBY_SCENE)


func _on_connection_failed() -> void:
	status_label.text = tr("Não foi possível conectar. Confira o IP e se o host está aberto.")
	_set_buttons_enabled(true)


func _on_connection_rejected(message: String) -> void:
	status_label.text = message
	_set_buttons_enabled(true)


func _player_name() -> String:
	var player_name := name_edit.text.strip_edges()
	return player_name if player_name != "" else tr("Jogador") + str(randi() % 1000)


func _set_buttons_enabled(enabled: bool) -> void:
	host_button.disabled = not enabled
	join_button.disabled = not enabled


## Permite subir instâncias de teste direto da linha de comando:
## godot --path . -- --host --name=Ana --autostart=3
## godot --path . -- --join=127.0.0.1 --name=Bia
func _apply_cmdline() -> void:
	if Network.cmdline_consumed:
		return
	Network.cmdline_consumed = true
	var args := Network.cmdline
	if args.has("name"):
		name_edit.text = args.name
	if args.has("host"):
		_on_host_pressed()
	elif args.has("join"):
		ip_edit.text = args.join
		_on_join_pressed()
