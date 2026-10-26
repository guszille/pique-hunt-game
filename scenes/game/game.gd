extends Node3D
## Raiz da partida: carrega o mapa escolhido, cria os jogadores (via
## MultiplayerSpawner) e oferece uma câmera livre para quem está só assistindo
## (ou para quem ligou a câmera livre de depuração, F2).

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var map: MapBase

@onready var players_root: Node3D = $Players
@onready var spawner: MultiplayerSpawner = $PlayerSpawner
@onready var spectator_camera: Camera3D = $SpectatorCamera


func _ready() -> void:
	var info: Dictionary = GameState.MAPS[GameState.current_map]
	map = load(info.scene).instantiate()
	map.name = "Map"
	add_child(map)
	move_child(map, 0)
	spectator_camera.global_position = map.get_seeker_release() + Vector3(0, 8, 6)
	spectator_camera.look_at(map.get_seeker_release())
	spawner.spawn_function = _spawn_player
	GameState.game_loaded(self)
	if Network.cmdline.has("screenshot"):
		_take_screenshot(Network.cmdline.screenshot, float(Network.cmdline.get("screenshot-delay", "8")))


func _process(_delta: float) -> void:
	# Quem não participa da rodada atual (entrou no meio) assiste pela câmera livre.
	var player := get_local_player()
	var watching := player == null or DebugTools.free_camera
	spectator_camera.active = watching
	if watching and not spectator_camera.current:
		spectator_camera.make_current()
	elif not watching and not player.camera.current:
		player.camera.make_current()


func spawn_player(id: int, spawn_position: Vector3, role: GameState.Role) -> void:
	spawner.spawn({
		"id": id,
		"position": spawn_position,
		"role": role,
		"name": Network.get_player_name(id),
		"color": Network.get_player_color(id),
	})


func clear_players() -> void:
	for player in players_root.get_children():
		players_root.remove_child(player)
		player.queue_free()


func remove_player(id: int) -> void:
	var player := get_player(id)
	if player:
		players_root.remove_child(player)
		player.queue_free()


func get_player(id: int) -> Player:
	return players_root.get_node_or_null(str(id)) as Player


func get_players() -> Array[Node]:
	return players_root.get_children()


func get_local_player() -> Player:
	return get_player(multiplayer.get_unique_id())


func play_sound_at(stream: AudioStream, at: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.unit_size = 6.0
	add_child(player)
	player.global_position = at
	player.finished.connect(player.queue_free)
	player.play()


func _spawn_player(data: Dictionary) -> Node:
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(data.id)
	player.position = data.position
	player.role = data.role
	player.display_name = data.name
	player.body_color = data.color
	return player


## Modo de teste: `--screenshot=/caminho.png --screenshot-delay=8` salva a tela da partida.
func _take_screenshot(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var image := get_viewport().get_texture().get_image()
	print("screenshot ", path, ": ", error_string(image.save_png(path)))
