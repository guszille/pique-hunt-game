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
