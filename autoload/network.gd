extends Node
## Conexão ENet (host/cliente) e registro dos jogadores conectados.
## O servidor é a fonte da verdade de `players` e replica a lista para todos.
##
## Antes de a conexão ser aceita, cliente e host trocam a versão do jogo na etapa
## de autenticação do SceneMultiplayer. Com versões diferentes, o host recusa o
## cliente, que volta ao menu com uma mensagem explicando.

signal players_changed
signal connection_succeeded
signal connection_failed
## O host recusou a conexão (versão diferente) ou não respondeu à checagem.
signal connection_rejected(message: String)
signal server_disconnected
signal peer_left(id: int)

const PORT := 7777
const MAX_PLAYERS := 10
const AUTH_TIMEOUT := 5.0
const COLORS: Array[Color] = [
	Color("e74c3c"), Color("3498db"), Color("2ecc71"), Color("f1c40f"), Color("9b59b6"),
	Color("e67e22"), Color("1abc9c"), Color("ff6fb5"), Color("95a5a6"), Color("34495e"),
]

## peer_id -> {"name": String, "color": Color, "score": int, "times_seeker": int}
var players: Dictionary = {}
var local_name := "Jogador"
## Versão deste jogo (`application/config/version` no project.godot).
var version: String = ProjectSettings.get_setting("application/config/version", "0")

## Clientes recusados pela checagem de versão (só no host).
var _rejected_peers := {}

## Opções vindas da linha de comando (`-- --host --name=A --autostart=3`), usadas em testes.
var cmdline := {}
var cmdline_consumed := false


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	var scene_multiplayer := multiplayer as SceneMultiplayer
	scene_multiplayer.auth_callback = _on_auth_data
	scene_multiplayer.auth_timeout = AUTH_TIMEOUT
	scene_multiplayer.peer_authenticating.connect(_on_peer_authenticating)
	scene_multiplayer.peer_authentication_failed.connect(_on_peer_authentication_failed)
	_parse_cmdline()


func is_online() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not (peer is OfflineMultiplayerPeer) \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func host_game(player_name: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	local_name = player_name
	players.clear()
	_register(1, player_name)
	return OK


func join_game(address: String, player_name: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	local_name = player_name
	players.clear()
	return OK


func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	players_changed.emit()


func get_player_name(id: int) -> String:
	return players.get(id, {}).get("name", "???")


func get_player_color(id: int) -> Color:
	return players.get(id, {}).get("color", Color.WHITE)


func add_score(id: int, amount: int) -> void:
	if players.has(id):
		players[id].score += amount


## Apenas no servidor: envia a lista de jogadores para todos.
func sync_players() -> void:
	if multiplayer.is_server():
		_receive_players.rpc(players)


func get_local_addresses() -> PackedStringArray:
	var result := PackedStringArray()
	for address in IP.get_local_addresses():
		if address.count(".") == 3 and not address.begins_with("127.") and not address.begins_with("169.254."):
			result.append(address)
	return result


func _register(id: int, player_name: String) -> void:
	player_name = player_name.strip_edges().substr(0, 16)
	if player_name.is_empty():
		player_name = "Jogador %d" % (players.size() + 1)
	players[id] = {
		"name": player_name,
		"color": _free_color(),
		"score": 0,
		"times_seeker": 0,
	}
	sync_players()
	GameState.on_player_registered(id)


func _free_color() -> Color:
	var used := players.values().map(func(p: Dictionary) -> Color: return p.color)
	for color in COLORS:
		if not color in used:
			return color
	return Color.from_hsv(randf(), 0.7, 0.9)


# --- Checagem de versão ---------------------------------------------------------

func _on_peer_authenticating(id: int) -> void:
	# O cliente se apresenta; o host só responde depois de ver a versão.
	if not multiplayer.is_server():
		(multiplayer as SceneMultiplayer).send_auth(id, var_to_bytes({"version": version}))


func _on_auth_data(id: int, data: PackedByteArray) -> void:
	var scene_multiplayer := multiplayer as SceneMultiplayer
	var info = bytes_to_var(data)
	if typeof(info) != TYPE_DICTIONARY:
		info = {}
	if multiplayer.is_server():
		var their_version := str(info.get("version", "desconhecida"))
		if their_version == version:
			scene_multiplayer.send_auth(id, var_to_bytes({"ok": true}))
			scene_multiplayer.complete_auth(id)
			return
		print("Conexão recusada: cliente %d tem a versão %s (host: %s)" % [id, their_version, version])
		_rejected_peers[id] = true
		# `message` vai pronta para clientes antigos; os novos montam o texto no
		# próprio idioma a partir de `host_version`.
		scene_multiplayer.send_auth(id, var_to_bytes({
			"ok": false,
			"host_version": version,
			"message": "Versões diferentes: você tem a %s e o host tem a %s.\nInstale a mesma versão do host para jogar juntos." % [their_version, version],
		}))
		# Dá tempo para a mensagem chegar antes de desconectar.
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if multiplayer.has_multiplayer_peer() and id in scene_multiplayer.get_authenticating_peers():
				scene_multiplayer.disconnect_peer(id))
	elif info.get("ok", false):
		scene_multiplayer.complete_auth(id)
	else:
		var message := tr("O host recusou a conexão.")
		if info.has("host_version"):
			message = tr("Versões diferentes: você tem a %s e o host tem a %s.\nInstale a mesma versão do host para jogar juntos.") \
				% [version, info.host_version]
		# Fecha a conexão fora do callback: o Godot ainda está processando este pacote.
		_reject.call_deferred(message)


func _on_peer_authentication_failed(id: int) -> void:
	if multiplayer.is_server():
		if not _rejected_peers.erase(id):
			print("Cliente %d não completou a checagem de versão (versão antiga do jogo?)." % id)
	elif multiplayer.multiplayer_peer:
		_reject.call_deferred(tr("O host não respondeu à checagem de versão.\nEle provavelmente tem uma versão antiga do jogo (anterior à %s).") % version)


func _reject(message: String) -> void:
	leave()
	connection_rejected.emit(message)


func _on_peer_connected(_id: int) -> void:
	pass # O cliente se registra sozinho via `_request_register` assim que conecta.


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	players.erase(id)
	sync_players()
	peer_left.emit(id)


func _on_connected_to_server() -> void:
	_request_register.rpc_id(1, local_name)
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()


@rpc("any_peer", "reliable")
func _request_register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if players.has(id):
		return
	_register(id, player_name)


@rpc("authority", "call_local", "reliable")
func _receive_players(data: Dictionary) -> void:
	players = data
	players_changed.emit()


func _parse_cmdline() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var parts := arg.substr(2).split("=", true, 1)
		cmdline[parts[0]] = parts[1] if parts.size() > 1 else ""
