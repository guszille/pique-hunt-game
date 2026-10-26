extends Node
## Máquina de estados da partida. O servidor decide tudo (fases, sorteio,
## capturas, disfarces e pontuação); os clientes apenas pedem ações via RPC
## e recebem o resultado.

signal phase_changed(phase: Phase)
signal settings_changed
signal votes_changed
signal notified(text: String, color: Color)

enum Phase { LOBBY, LOADING, DRAW, PREP, HUNT, END }
enum Role { HIDER, SEEKER }
enum Mode { CLASSIC, INFECTION }
## Teclas de depuração que dependem do servidor (veja DebugTools).
enum DebugAction { TOGGLE_ROLE, SKIP_PHASE, NEXT_MAP, TOGGLE_PAUSE }

const GAME_SCENE := "res://scenes/game/game.tscn"
const LOBBY_SCENE := "res://scenes/ui/lobby.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## `prep_time` e `hunt_time` são os tempos sugeridos (veja `suggested_times`).
## Nomes e descrições de mapas e modos são chaves de tradução (traduza com tr()).
const MAPS: Array[Dictionary] = [
	{"name": "Casa", "scene": "res://scenes/maps/house.tscn", "prep_time": 50, "hunt_time": 300,
		"description": "Sobrado com porão, sótão, garagem e quintal, cheio de móveis."},
	{"name": "Fábrica", "scene": "res://scenes/maps/factory.tscn", "prep_time": 50, "hunt_time": 330,
		"description": "Galpão alto com esteiras, prateleiras, barris e mezanino."},
	{"name": "Parque", "scene": "res://scenes/maps/park.tscn", "prep_time": 50, "hunt_time": 330,
		"description": "Parque de diversões ao entardecer: carrossel, roda-gigante, barracas e labirinto."},
]
## Valor de `settings.map` que deixa os jogadores votarem no mapa.
const MAP_VOTE := -1

const MODES: Array[Dictionary] = [
	{"name": "Clássico", "description": "Quem é pego sai da rodada e assiste."},
	{"name": "Infecção", "description": "Quem é pego vira ajudante do procurador!"},
]

const LOADING_TIMEOUT := 15.0
const DRAW_TIME := 4.0
const END_TIME := 8.0
const CATCH_RANGE := 2.5
const TRANSFORM_RANGE := 4.0
const DISGUISE_COOLDOWN := 1.5
const MISS_PENALTY := 2.0
## Tempo que um ajudante recém-infectado espera antes de poder pegar alguém.
const INFECTION_COOLDOWN := 3.0
const WHISTLE_START := 60.0
const WHISTLE_INTERVAL := 12.0
const SURVIVE_TICK := 30.0
## Tempos automáticos: segundos a mais de caçada por escondido acima de 3, até o teto.
const HUNT_PER_EXTRA_HIDER := 15
const MAX_HUNT_TIME := 600

const COLOR_INFO := Color("ecf0f1")
const COLOR_GOOD := Color("2ecc71")
const COLOR_BAD := Color("e74c3c")

var settings := {"map": MAP_VOTE, "mode": Mode.CLASSIC, "auto_time": true, "prep_time": 50, "hunt_time": 300}
## Mapa da partida atual (o resultado da votação, quando há votação).
var current_map := 0
## Votos do lobby: peer_id -> índice em MAPS. Replicado pelo servidor.
var votes := {}
var phase := Phase.LOBBY
var time_left := 0.0
var seeker_id := 0
var round_peers: Array = []
## Resultado da rodada, como mensagem [chave, args...] (veja Language.format).
var result_message: Array = []
## Cronômetro parado pela tecla de depuração F6.
var timer_paused := false
## Mensagem exibida no menu principal ao voltar (ex.: "O host saiu"), já traduzida.
var menu_message := ""

var game: Node = null

# Apenas no servidor.
var _loaded := {}
var _last_seeker_id := 0
var _last_disguise := {}
var _catch_blocked_until := {}
var _map_announcement: Array = []
var _whistle_timer := 0.0
var _survive_timer := 0.0


func _ready() -> void:
	Network.peer_left.connect(_on_peer_left)
	Network.server_disconnected.connect(_on_server_disconnected)


func _process(delta: float) -> void:
	if phase == Phase.LOBBY or timer_paused:
		return
	time_left = maxf(time_left - delta, 0.0)
	if not multiplayer.is_server():
		return
	if phase == Phase.HUNT:
		_tick_hunt(delta)
	if time_left <= 0.0:
		_advance_phase()


func _advance_phase() -> void:
	match phase:
		Phase.LOADING:
			_begin_round()
		Phase.DRAW:
			_start_prep()
		Phase.PREP:
			_start_hunt()
		Phase.HUNT:
			_end_round(false)
		Phase.END:
			_next_round()


# --- Consultas usadas pela interface e pelo jogador -------------------------

func is_in_round(id: int) -> bool:
	return id in round_peers


func is_peer_loaded(id: int) -> bool:
	return _loaded.has(id)


func get_players() -> Array:
	return game.get_players() if is_instance_valid(game) else []


func count_hiders() -> Vector2i:
	## x = escondidos ainda livres, y = total de escondidos.
	var alive := 0
	var total := 0
	for player in get_players():
		if player.peer_id != seeker_id:
			total += 1
			if player.role == Role.HIDER and not player.caught:
				alive += 1
	return Vector2i(alive, total)


func is_infection() -> bool:
	return settings.get("mode", Mode.CLASSIC) == Mode.INFECTION


func can_move() -> bool:
	return phase == Phase.PREP or phase == Phase.HUNT


## Jogadores necessários para começar. Em builds de depuração dá para testar sozinho.
func min_players() -> int:
	return 1 if DebugTools.enabled else 2


# --- Lobby -------------------------------------------------------------------

func set_settings(new_settings: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	_receive_settings.rpc(new_settings)
	if new_settings.map != MAP_VOTE and not votes.is_empty():
		_receive_votes.rpc({})


## Tempos sugeridos para o mapa e o número de jogadores: x = preparação, y = caçada.
func suggested_times(map_index: int, player_count: int) -> Vector2i:
	var info: Dictionary = MAPS[clampi(map_index, 0, MAPS.size() - 1)]
	var extra_hiders := maxi(0, player_count - 1 - 3)
	return Vector2i(info.prep_time, mini(info.hunt_time + extra_hiders * HUNT_PER_EXTRA_HIDER, MAX_HUNT_TIME))


func is_map_vote() -> bool:
	return settings.map == MAP_VOTE


func vote_map(index: int) -> void:
	_request_vote.rpc_id(1, index)


## Quantidade de votos de cada mapa (mesma ordem de MAPS).
func count_votes() -> Array[int]:
	var counts: Array[int] = []
	counts.resize(MAPS.size())
	for index: int in votes.values():
		counts[index] += 1
	return counts


func start_game() -> void:
	if not multiplayer.is_server() or Network.players.size() < min_players():
		return
	for id in Network.players:
		Network.players[id].score = 0
		Network.players[id].times_seeker = 0
	Network.sync_players()
	var map_index := _choose_map()
	if settings.get("auto_time", false):
		var times := suggested_times(map_index, Network.players.size())
		settings.prep_time = times.x
		settings.hunt_time = times.y
	_receive_votes.rpc({})
	_load_map(map_index)


## Apenas no servidor: todos carregam a cena da partida com o mapa indicado.
func _load_map(map_index: int) -> void:
	if is_instance_valid(game):
		game.clear_players()
	_loaded.clear()
	_enter_game.rpc(settings, map_index)
	_set_phase(Phase.LOADING, LOADING_TIMEOUT)


## Mapa fixo do host, ou o mais votado. Empate e falta de votos são sorteados.
func _choose_map() -> int:
	if not is_map_vote():
		_map_announcement = []
		return clampi(settings.map, 0, MAPS.size() - 1)
	var counts := count_votes()
	var best: int = counts.max()
	var candidates := range(MAPS.size()).filter(func(i: int) -> bool: return counts[i] == best)
	var chosen: int = candidates.pick_random()
	var map_name := StringName(MAPS[chosen].name)
	if best == 0:
		_map_announcement = ["Ninguém votou: o mapa sorteado foi %s.", map_name]
	elif candidates.size() > 1:
		_map_announcement = ["Empate na votação! O mapa sorteado foi %s.", map_name]
	else:
		_map_announcement = ["Mapa escolhido na votação: %s (%d de %d votos).", map_name, best, votes.size()]
	return chosen


func return_to_lobby() -> void:
	if multiplayer.is_server():
		_send_everyone_to_lobby()


## Apenas no servidor. Remove os jogadores antes de trocar de cena, para os
## clientes receberem a remoção enquanto ainda estão na partida.
func _send_everyone_to_lobby() -> void:
	if is_instance_valid(game):
		game.clear_players()
	_go_to_lobby.rpc()


func leave_to_menu(message := "") -> void:
	menu_message = message
	Network.leave()
	_reset()
	get_tree().change_scene_to_file(MENU_SCENE)


## Chamado pelo Network quando um jogador termina de se registrar.
func on_player_registered(id: int) -> void:
	if not multiplayer.is_server() or id == 1:
		return
	_receive_settings.rpc_id(id, settings)
	_receive_votes.rpc_id(id, votes)
	if phase != Phase.LOBBY:
		# Partida em andamento: entra como espectador e joga na próxima rodada.
		_enter_game.rpc_id(id, settings, current_map)


# --- Pedidos dos jogadores ---------------------------------------------------

## Chamado pelo game.gd quando a cena da partida termina de carregar.
func game_loaded(game_node: Node) -> void:
	game = game_node
	_peer_loaded.rpc_id(1)


func request_disguise(prop: Prop) -> void:
	_request_disguise.rpc_id(1, prop.get_path())


func request_revert() -> void:
	_request_revert.rpc_id(1)


func request_catch(target_id: int) -> void:
	_request_catch.rpc_id(1, target_id)


@rpc("any_peer", "call_local", "reliable")
func _peer_loaded() -> void:
	if not multiplayer.is_server():
		return
	var id := _sender()
	_loaded[id] = true
	_receive_loaded.rpc(_loaded.keys())
	if id != 1:
		_receive_phase.rpc_id(id, phase, time_left, seeker_id, round_peers, result_message)
		_receive_timer_paused.rpc_id(id, timer_paused, time_left)
	if phase == Phase.LOADING and Network.players.keys().all(func(p: int) -> bool: return _loaded.has(p)):
		_begin_round()


@rpc("any_peer", "call_local", "reliable")
func _request_disguise(prop_path: NodePath) -> void:
	if not multiplayer.is_server() or not can_move():
		return
	var id := _sender()
	var player = game.get_player(id)
	if player == null or player.role != Role.HIDER or player.caught:
		return
	var now := _now()
	if now - _last_disguise.get(id, -100.0) < DISGUISE_COOLDOWN:
		return
	var prop := get_node_or_null(prop_path) as Prop
	if prop == null or not prop.disguisable:
		return
	if player.global_position.distance_to(prop.global_position) > TRANSFORM_RANGE + 2.0:
		return
	_last_disguise[id] = now
	player.disguise = prop.get_disguise()


@rpc("any_peer", "call_local", "reliable")
func _request_revert() -> void:
	if not multiplayer.is_server():
		return
	var player = game.get_player(_sender())
	if player and not player.caught:
		player.disguise = {}


@rpc("any_peer", "call_local", "reliable")
func _request_catch(target_id: int) -> void:
	if not multiplayer.is_server() or phase != Phase.HUNT:
		return
	var id := _sender()
	var seeker = game.get_player(id)
	if seeker == null or seeker.role != Role.SEEKER:
		return
	if _now() < _catch_blocked_until.get(id, 0.0):
		return
	if target_id == 0:
		_catch_blocked_until[id] = _now() + MISS_PENALTY
		_penalize.rpc_id(id)
		return
	var target = game.get_player(target_id)
	if target == null or target.role != Role.HIDER or target.caught:
		return
	if seeker.global_position.distance_to(target.global_position) > CATCH_RANGE + 2.0:
		return
	var seeker_name := Network.get_player_name(id)
	var target_name := Network.get_player_name(target_id)
	Network.add_score(id, 3)
	Network.sync_players()
	if is_infection():
		# Infecção: o escondido volta à forma de alien e passa a procurar também.
		target.disguise = {}
		target.role = Role.SEEKER
		target.infected = true
		_catch_blocked_until[target_id] = _now() + INFECTION_COOLDOWN
		_infect.rpc_id(target_id)
		_announce.rpc(["%s pegou %s! Agora %s também procura.", seeker_name, target_name, target_name], COLOR_BAD)
	else:
		target.caught = true
		_announce.rpc(["%s pegou %s!", seeker_name, target_name], COLOR_BAD)
	_play_catch.rpc(target.global_position)
	_check_end()


# --- Fluxo da rodada (servidor) ----------------------------------------------

func _begin_round() -> void:
	if not is_instance_valid(game):
		return
	round_peers = Network.players.keys().filter(func(id: int) -> bool: return _loaded.has(id))
	if round_peers.size() < min_players():
		_send_everyone_to_lobby()
		return
	# Teste solo (só em depuração): ninguém procura e o jogador começa escondido.
	var solo := round_peers.size() == 1
	seeker_id = 0 if solo else _draw_seeker()
	if not solo:
		_last_seeker_id = seeker_id
		Network.players[seeker_id].times_seeker += 1
	_last_disguise.clear()
	_catch_blocked_until.clear()

	game.clear_players()
	var spawns: Array[Vector3] = game.map.get_hider_spawns()
	spawns.shuffle()
	var index := 0
	for id: int in round_peers:
		if id == seeker_id:
			game.spawn_player(id, game.map.get_seeker_cage(), Role.SEEKER)
		else:
			game.spawn_player(id, spawns[index % spawns.size()], Role.HIDER)
			index += 1
	Network.sync_players()
	result_message = []
	if solo:
		_start_prep()
	else:
		_set_phase(Phase.DRAW, DRAW_TIME)
	if not _map_announcement.is_empty():
		_announce.rpc(_map_announcement, COLOR_INFO)
		_map_announcement = []


func _draw_seeker() -> int:
	## Sorteio ponderado: quem procurou menos vezes tem mais chance,
	## e ninguém procura duas rodadas seguidas.
	var candidates := round_peers.filter(func(id: int) -> bool: return id != _last_seeker_id)
	if candidates.is_empty():
		candidates = round_peers.duplicate()
	var weights: Array[float] = []
	var total := 0.0
	for id: int in candidates:
		var weight: float = 1.0 / (1.0 + Network.players[id].times_seeker)
		weights.append(weight)
		total += weight
	var roll := randf() * total
	for i in candidates.size():
		roll -= weights[i]
		if roll <= 0.0:
			return candidates[i]
	return candidates.back()


func _start_prep() -> void:
	_set_phase(Phase.PREP, settings.prep_time)


func _start_hunt() -> void:
	_whistle_timer = 0.0
	_survive_timer = 0.0
	if seeker_id == 0:
		_set_phase(Phase.HUNT, settings.hunt_time)
		return
	_teleport.rpc_id(seeker_id, game.map.get_seeker_release())
	_set_phase(Phase.HUNT, settings.hunt_time)
	_announce.rpc(["Lá vou eu! %s começou a procurar.", Network.get_player_name(seeker_id)], COLOR_INFO)


func _tick_hunt(delta: float) -> void:
	_survive_timer += delta
	if _survive_timer >= SURVIVE_TICK:
		_survive_timer -= SURVIVE_TICK
		for player in _alive_hiders():
			Network.add_score(player.peer_id, 1)
		Network.sync_players()
	if time_left <= WHISTLE_START:
		_whistle_timer -= delta
		if _whistle_timer <= 0.0:
			_whistle_timer = WHISTLE_INTERVAL
			for player in _alive_hiders():
				_whistle.rpc(player.peer_id)


func _alive_hiders() -> Array:
	return get_players().filter(func(p) -> bool: return p.role == Role.HIDER and not p.caught)


func _check_end() -> void:
	if phase != Phase.PREP and phase != Phase.HUNT:
		return
	# Teste solo: a rodada só acaba pelo tempo (ou pelo F4).
	if round_peers.size() < 2:
		return
	# Na infecção, a rodada continua se algum ajudante ainda estiver no jogo.
	if get_players().all(func(p) -> bool: return p.role != Role.SEEKER):
		_end_round(false, ["O procurador saiu. Rodada anulada."])
	elif _alive_hiders().is_empty():
		_end_round(true)


func _end_round(seeker_won: bool, reason: Array = []) -> void:
	if not reason.is_empty():
		result_message = reason
	elif seeker_won:
		Network.add_score(seeker_id, 5)
		if is_infection():
			for player in get_players():
				if player.infected:
					Network.add_score(player.peer_id, 2)
			result_message = ["Infecção completa! %s e os ajudantes pegaram todo mundo.", Network.get_player_name(seeker_id)]
		else:
			result_message = ["%s pegou todo mundo!", Network.get_player_name(seeker_id)]
	else:
		var names := PackedStringArray()
		for player in _alive_hiders():
			Network.add_score(player.peer_id, 5)
			names.append(Network.get_player_name(player.peer_id))
		result_message = ["Os escondidos venceram! Sobreviveram: %s", ", ".join(names)]
	Network.sync_players()
	_set_phase(Phase.END, END_TIME)


func _next_round() -> void:
	_begin_round()


func _set_phase(new_phase: Phase, duration: float) -> void:
	_receive_phase.rpc(new_phase, duration, seeker_id, round_peers, result_message)


func _on_peer_left(id: int) -> void:
	if votes.has(id):
		votes.erase(id)
		_receive_votes.rpc(votes)
	_loaded.erase(id)
	_receive_loaded.rpc(_loaded.keys())
	if is_instance_valid(game):
		game.remove_player(id)
	if phase == Phase.LOBBY or phase == Phase.LOADING:
		return
	if Network.players.size() < min_players():
		_send_everyone_to_lobby()
		return
	if phase == Phase.DRAW and id == seeker_id:
		_end_round(false, ["O procurador saiu. Rodada anulada."])
		return
	_check_end()


func _on_server_disconnected() -> void:
	leave_to_menu(tr("A conexão com o host caiu."))


func _reset() -> void:
	phase = Phase.LOBBY
	time_left = 0.0
	seeker_id = 0
	round_peers = []
	result_message = []
	timer_paused = false
	game = null
	_loaded.clear()
	_last_seeker_id = 0
	votes.clear()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _sender() -> int:
	var id := multiplayer.get_remote_sender_id()
	return id if id != 0 else multiplayer.get_unique_id()


# --- Depuração (servidor) -------------------------------------------------------

func request_debug(action: DebugAction) -> void:
	_request_debug.rpc_id(1, action)


@rpc("any_peer", "call_local", "reliable")
func _request_debug(action: DebugAction) -> void:
	if not multiplayer.is_server() or not DebugTools.enabled or not is_instance_valid(game):
		return
	if phase == Phase.LOBBY or phase == Phase.LOADING:
		return
	var id := _sender()
	var who := Network.get_player_name(id)
	match action:
		DebugAction.TOGGLE_ROLE:
			_debug_toggle_role(id)
		DebugAction.SKIP_PHASE:
			_announce.rpc(["[depuração] %s pulou a fase.", who], COLOR_INFO)
			_advance_phase()
		DebugAction.NEXT_MAP:
			var next := (current_map + 1) % MAPS.size()
			_map_announcement = ["[depuração] %s trocou o mapa para %s.", who, StringName(MAPS[next].name)]
			_load_map(next)
		DebugAction.TOGGLE_PAUSE:
			_receive_timer_paused.rpc(not timer_paused, time_left)
			_announce.rpc(["[depuração] %s pausou o cronômetro." if timer_paused else "[depuração] %s retomou o cronômetro.", who], COLOR_INFO)


func _debug_toggle_role(id: int) -> void:
	var player = game.get_player(id)
	if player == null:
		return
	var was_caught: bool = player.caught
	player.disguise = {}
	player.caught = false
	player.infected = false
	player.role = Role.HIDER if player.role == Role.SEEKER else Role.SEEKER
	_catch_blocked_until.erase(id)
	if was_caught:
		_teleport.rpc_id(id, game.map.get_hider_spawns().pick_random())
	_announce.rpc(["[depuração] %s agora é procurador." if player.role == Role.SEEKER else "[depuração] %s agora é escondido.",
		Network.get_player_name(id)], COLOR_INFO)


# --- RPCs recebidos por todos -------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _receive_settings(new_settings: Dictionary) -> void:
	settings = new_settings
	settings_changed.emit()


@rpc("authority", "call_local", "reliable")
func _receive_loaded(ids: Array) -> void:
	_loaded.clear()
	for id: int in ids:
		_loaded[id] = true
	for player in get_players():
		player.refresh_visibility()


@rpc("authority", "call_local", "reliable")
func _enter_game(new_settings: Dictionary, map_index: int) -> void:
	settings = new_settings
	current_map = map_index
	get_tree().change_scene_to_file(GAME_SCENE)


@rpc("any_peer", "call_local", "reliable")
func _request_vote(index: int) -> void:
	if not multiplayer.is_server() or phase != Phase.LOBBY or not is_map_vote():
		return
	if index < 0 or index >= MAPS.size():
		return
	votes[_sender()] = index
	_receive_votes.rpc(votes)


@rpc("authority", "call_local", "reliable")
func _receive_votes(new_votes: Dictionary) -> void:
	votes = new_votes
	votes_changed.emit()


@rpc("authority", "call_local", "reliable")
func _go_to_lobby() -> void:
	_reset()
	get_tree().change_scene_to_file(LOBBY_SCENE)


@rpc("authority", "call_local", "reliable")
func _receive_phase(new_phase: Phase, duration: float, seeker: int, peers: Array, result: Array) -> void:
	phase = new_phase
	time_left = duration
	seeker_id = seeker
	round_peers = peers
	result_message = result
	print("[peer %d] fase: %s (%ds) procurador: %s" % [multiplayer.get_unique_id(), Phase.keys()[phase], int(duration), Network.get_player_name(seeker)])
	phase_changed.emit(phase)


@rpc("authority", "call_local", "reliable")
func _receive_timer_paused(paused: bool, remaining: float) -> void:
	timer_paused = paused
	time_left = remaining


@rpc("authority", "call_local", "reliable")
func _announce(message: Array, color: Color) -> void:
	var text := Language.format(message)
	print("[peer %d] aviso: %s" % [multiplayer.get_unique_id(), text])
	notified.emit(text, color)


@rpc("authority", "call_local", "reliable")
func _teleport(position: Vector3) -> void:
	if is_instance_valid(game):
		var player = game.get_local_player()
		if player:
			player.teleport(position)


@rpc("authority", "call_local", "reliable")
func _penalize() -> void:
	if is_instance_valid(game):
		var player = game.get_local_player()
		if player:
			player.apply_penalty(MISS_PENALTY)
	notified.emit(tr("Errou! Isso era só um objeto."), COLOR_BAD)


@rpc("authority", "call_local", "reliable")
func _infect() -> void:
	if is_instance_valid(game):
		var player = game.get_local_player()
		if player:
			player.block_catch(INFECTION_COOLDOWN)
	notified.emit(tr("Você foi pego! Agora você ajuda a procurar (pode pegar em %d s).") % INFECTION_COOLDOWN, COLOR_BAD)


@rpc("authority", "call_local", "unreliable")
func _whistle(id: int) -> void:
	if is_instance_valid(game):
		var player = game.get_player(id)
		if player:
			player.play_whistle()


@rpc("authority", "call_local", "reliable")
func _play_catch(position: Vector3) -> void:
	if is_instance_valid(game):
		game.play_sound_at(Sfx.catch_sound(), position)
