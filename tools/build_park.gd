extends "res://tools/map_builder.gd"
## Gera res://scenes/maps/park.tscn (mapa "Parque"): parque de diversões ao
## entardecer, ao ar livre e cercado. Brinquedos parados.
## Uso: godot --headless --path . -s res://tools/build_park.gd
##
## Planta (x para a direita, z para baixo), parque de x -20..38, z -38..20.
## Parte antiga (x -20..20, z -20..20):
##   Bate-bate (NO)      | Trem fantasma (N) | Roda-gigante (NE)
##   Barracas de jogos (O) | Carrossel (centro) | Praça de alimentação (L)
##   Piscina de bolinhas (SO) | Entrada (S)   | Labirinto de espelhos (SE)
## Ampliação ao norte (z -38..-22): palco com plateia, lago com píer, montanha-russa.
## Ampliação a leste (x 21..38): xícaras malucas e mini golfe, fliperama, loja de
## prêmios e banheiros. Uma rua contorna a parte antiga (z -22..-20 e x 19..21).

const PARK_MIN := Vector2(-20, -38)
const PARK_MAX := Vector2(38, 20)
const FENCE_HEIGHT := 2.2
const WHEEL_CENTER := Vector3(12, 8.6, -12)
const WHEEL_RADIUS := 7.0
const WHEEL_GAP := 0.7

const LAMP := Color("ffcc80")

var rng := RandomNumberGenerator.new()
var lights: Node3D
var glows: Node3D
var _path_layer := 0


func _init() -> void:
	out_path = "res://scenes/maps/park.tscn"
	map_name = "Parque"
	root_name = "Park"
	wall_height = FENCE_HEIGHT
	rng.seed = 1998


func _build() -> void:
	_add_sunset()
	_add_ground()
	lights = add_group("Luzes")
	glows = add_group("Brilhos")
	add_content_groups()
	_add_fence_and_entrance()
	_add_carousel()
	_add_ferris_wheel()
	_add_bumper_cars()
	_add_game_booths()
	_add_food_court()
	_add_ball_pit()
	_add_mirror_maze()
	_add_ghost_train()
	_add_trees_and_lamps()
	_add_stage()
	_add_lake()
	_add_roller_coaster()
	_add_teacups()
	_add_mini_golf()
	_add_arcade()
	_add_prize_shop()
	_add_restrooms()
	_add_new_paths_decor()
	add_markers([
		Vector3(-4, 0.1, 10), Vector3(4, 0.1, 10), Vector3(-10, 0.1, 0), Vector3(10, 0.1, 0),
		Vector3(0, 0.1, -10), Vector3(-12, 0.1, -6), Vector3(12, 0.1, -7), Vector3(-5.2, 0.1, 10.2),
		Vector3(7, 0.1, 12), Vector3(-2, 0.1, -11),
		Vector3(-12, 0.1, -25.5), Vector3(1, 0.1, -22.8), Vector3(29, 0.1, -31), Vector3(20, 0.1, -12),
		Vector3(33.5, 0.1, -13.0), Vector3(24, 0.1, 0), Vector3(34, 0.1, 0), Vector3(25, 0.1, 15),
		Vector3(34, 0.1, 11), Vector3(17.5, 0.1, -36),
	], Vector3(0, 0.1, 26), Vector3(0, 0.1, 16))


# --- Ambiente e estrutura --------------------------------------------------------

func _add_sunset() -> void:
	var env := add_environment(Color("2f4577"), Color("ff9e5e"), 0.35, 0.9)
	var sky_material := env.sky.sky_material as ProceduralSkyMaterial
	sky_material.ground_horizon_color = Color("ff9e5e")
	sky_material.ground_bottom_color = Color("3a2a3a")
	env.fog_enabled = true
	env.fog_light_color = Color("f0a070")
	env.fog_density = 0.006
	env.fog_sky_affect = 0.2
	env.glow_enabled = true
	var sun := map_root.get_node("Sun") as DirectionalLight3D
	sun.rotation_degrees = Vector3(-14, -120, 0)
	sun.light_color = Color("ffa86b")


func _add_ground() -> void:
	var floors := add_group("Floors")
	add_floor(floors, "GramaFora", Rect2(-90, -90, 180, 180), Color("4f7a3a"), -0.02)
	add_floor(floors, "Grama", Rect2(PARK_MIN, PARK_MAX - PARK_MIN), Color("6a994e"))
	add_seeker_cage(floors, Vector3(0, 0, 26))

	# Caminhos de terra batida (sem colisão, pintados sobre a grama).
	var paths := add_group("Caminhos", floors)
	for rect in [
		Rect2(-2, 7.5, 4, 12.4), Rect2(-2, -12, 4, 4.5),            # avenida sul e norte
		Rect2(-7.5, -7.5, 15, 1.5), Rect2(-7.5, 6, 15, 1.5),      # anel do carrossel
		Rect2(-7.5, -6, 1.5, 12), Rect2(6, -6, 1.5, 12),
		Rect2(-14.6, -1, 7.1, 2), Rect2(7.5, -1, 11.5, 2),        # avenida leste-oeste
		Rect2(-20, -22, 58, 2), Rect2(19, -38, 2, 58),            # ruas da ampliação
		Rect2(21, -1, 1, 2), Rect2(-2, -24, 4, 2), Rect2(5, -24, 2, 2),
	]:
		_path_layer += 1
		add_floor(paths, "Caminho", rect, Color("c9a77c"), 0.004 + _path_layer * 0.002, false)


func _add_fence_and_entrance() -> void:
	var fence := Color("37474f")
	wall_x(PARK_MIN.y, PARK_MIN.x, PARK_MAX.x, [], fence)
	wall_x(PARK_MAX.y, PARK_MIN.x, PARK_MAX.x, [], fence)
	wall_z(PARK_MIN.x, PARK_MIN.y, PARK_MAX.y, [], fence)
	wall_z(PARK_MAX.x, PARK_MIN.y, PARK_MAX.y, [], fence)

	# Portal de entrada (o portão fica fechado durante a brincadeira).
	decor_item("PortalPilar", BOX, Vector3(0.8, 4.5, 0.8), Color("8e24aa"), Vector3(-3, 0, 19.4))
	decor_item("PortalPilar", BOX, Vector3(0.8, 4.5, 0.8), Color("8e24aa"), Vector3(3, 0, 19.4))
	decor_item("PortalLetreiro", BOX, Vector3(6.8, 1.0, 0.8), Color("f9a825"), Vector3(0, 4.5, 19.4))
	add_glow(glows, "Neon", Vector3(0, 5.0, 18.95), Vector3(6.0, 0.15, 0.1), Color("ff4081"))
	for x in [-2.0, 0.0, 2.0]:
		add_glow(glows, "Lampada", Vector3(x, 5.6, 19.4), Vector3.ONE * 0.3, Color("fff59d"), true)

	_ticket_booth(Vector3(-7.0, 0, 17.5), Color("e53935"))
	_ticket_booth(Vector3(7.0, 0, 17.5), Color("1e88e5"))
	for x in [-3.5, -2.6, 2.6, 3.5]:
		decor_item("Catraca", CYLINDER, Vector3(0.3, 1.0, 0.3), Color("90a4ae"), Vector3(x, 0, 15))
	for x in [-5.0, 5.0]:
		item("banco_praca", Vector3(x, 0, 13.6), 180)
	item("lixeira_parque", Vector3(-6.2, 0, 13.6))
	item("lixeira_parque", Vector3(6.2, 0, 13.6))
	item("cone", Vector3(-4.2, 0, 18.6))
	item("cone", Vector3(4.2, 0, 18.6))
	item("totem_mapa", Vector3(-3.2, 0, 11.0), 90)
	for at in [Vector3(-5.4, 0, 12.0), Vector3(-6.1, 0, 12.0), Vector3(7.8, 0, 12.4)]:
		item("carrinho_bebe", at, 0, ["1e88e5" if at.x < -6 else "e91e63", "212121", "bbdefb"])


func _ticket_booth(at: Vector3, color: Color) -> void:
	decor_item("Bilheteria", BOX, Vector3(2.2, 2.4, 1.8), color, at)
	decor_item("BilheteriaTeto", PRISM, Vector3(2.6, 0.6, 2.2), Color("fafafa"), at + Vector3(0, 2.4, 0))
	decor_item("BilheteriaBalcao", BOX, Vector3(1.4, 0.1, 0.4), Color("fafafa"), at + Vector3(0, 1.0, -1.1))


# --- Brinquedos ----------------------------------------------------------------------

func _add_carousel() -> void:
	decor_item("CarrosselBase", CYLINDER, Vector3(9, 0.3, 9), Color("ad1457"), Vector3(0, 0, 0))
	decor_item("CarrosselMastro", CYLINDER, Vector3(0.7, 3.5, 0.7), Color("fdd835"), Vector3(0, 0.3, 0))
	decor_item("CarrosselFaixa", CYLINDER, Vector3(10.4, 0.4, 10.4), Color("fdd835"), Vector3(0, 3.8, 0))
	decor_item("CarrosselTeto", CONE, Vector3(10.4, 1.8, 10.4), Color("e91e63"), Vector3(0, 4.2, 0))
	var horse_colors := [Color("fafafa"), Color("8d6e63"), Color("212121"), Color("f8bbd0")]
	for i in 8:
		var angle := TAU * i / 8.0
		var at := Vector3(cos(angle), 0, sin(angle)) * 3.2
		var yaw := -rad_to_deg(angle)
		var forward := Vector3(sin(angle), 0, -cos(angle))
		decor_item("HasteBaixo", CYLINDER, Vector3(0.08, 0.6, 0.08), Color("fdd835"), at + Vector3(0, 0.3, 0))
		decor_item("Cavalinho", BOX, Vector3(0.35, 0.45, 1.0), horse_colors[i % 4], at + Vector3(0, 0.9, 0), yaw)
		decor_item("CavalinhoCabeca", BOX, Vector3(0.25, 0.45, 0.3), horse_colors[i % 4], at + Vector3(0, 1.25, 0) + forward * 0.65, yaw)
		decor_item("HasteCima", CYLINDER, Vector3(0.08, 2.45, 0.08), Color("fdd835"), at + Vector3(0, 1.35, 0))
	for i in 16:
		var angle := TAU * i / 16.0
		add_glow(glows, "LampadaCarrossel", Vector3(cos(angle) * 5.25, 4.0, sin(angle) * 5.25), Vector3.ONE * 0.22, Color("fff59d"), true)
	add_light(lights, Vector3(0, 3.3, 0), 7.0, 1.2, Color("ffe082"))

	# Bancos e canteiros em volta.
	for i in 6:
		var angle := TAU * (i + 0.5) / 6.0
		var at := Vector3(cos(angle), 0, sin(angle)) * 8.6
		# O banco olha para o carrossel.
		item("banco_praca", at, rad_to_deg(atan2(-at.x, -at.z)))
	for corner in [Vector3(-9.5, 0, -6.5), Vector3(9.5, 0, 9.5), Vector3(-9.5, 0, 9.5)]:
		decor_item("Canteiro", CYLINDER, Vector3(1.2, 0.5, 1.2), Color("8d6e63"), corner)
		prop("Arbusto", SPHERE, Vector3(0.8, 0.8, 0.8), Color("43a047"), corner + Vector3(0, 0.5, 0))
	item("lixeira_parque", Vector3(5.6, 0, 6.6))
	item("lixeira_parque", Vector3(-5.6, 0, -6.6))
	prop("BolaGrande", SPHERE, Vector3(0.5, 0.5, 0.5), Color("e53935"), Vector3(-6.6, 0, 3))
	item("medidor_altura", Vector3(7.2, 0, 1.2), -90)


func _add_ferris_wheel() -> void:
	var wheel := CSGCombiner3D.new()
	wheel.name = "RodaGigante"
	wheel.use_collision = true
	map_root.add_child(wheel)
	var white := PropBuilder.get_material(Color("eceff1"))
	var steel := PropBuilder.get_material(Color("607d8b"))
	for side in [-WHEEL_GAP, WHEEL_GAP]:
		var outer := _csg_cylinder(wheel, "Aro", WHEEL_RADIUS, 0.3, WHEEL_CENTER + Vector3(0, 0, side), white)
		outer.rotation_degrees.x = 90
		var inner := _csg_cylinder(wheel, "AroVazado", WHEEL_RADIUS - 0.3, 0.6, WHEEL_CENTER + Vector3(0, 0, side), white)
		inner.rotation_degrees.x = 90
		inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	for side in [-WHEEL_GAP, WHEEL_GAP]:
		for i in 6:
			var spoke := CSGBox3D.new()
			spoke.name = "Raio"
			spoke.size = Vector3(0.15, (WHEEL_RADIUS - 0.3) * 2.0, 0.15)
			spoke.position = WHEEL_CENTER + Vector3(0, 0, side)
			spoke.rotation_degrees.z = 30.0 * i
			spoke.material = white
			wheel.add_child(spoke)
	var hub := _csg_cylinder(wheel, "Eixo", 0.25, 3.2, WHEEL_CENTER, steel)
	hub.rotation_degrees.x = 90
	# Pernas em "A" dos dois lados.
	var leg_spread := 3.5
	var leg_length := Vector2(leg_spread, WHEEL_CENTER.y).length()
	var lean := rad_to_deg(atan2(leg_spread, WHEEL_CENTER.y))
	for z in [WHEEL_CENTER.z - 1.4, WHEEL_CENTER.z + 1.4]:
		for direction in [-1.0, 1.0]:
			var leg := CSGBox3D.new()
			leg.name = "Perna"
			leg.size = Vector3(0.35, leg_length, 0.35)
			leg.position = Vector3(WHEEL_CENTER.x + direction * leg_spread * 0.5, WHEEL_CENTER.y * 0.5, z)
			leg.rotation_degrees.z = direction * lean
			leg.material = steel
			wheel.add_child(leg)
	# Cabines penduradas entre os dois aros.
	var cabin_colors := [Color("e53935"), Color("fdd835"), Color("1e88e5"), Color("43a047")]
	for i in 12:
		var angle := TAU * i / 12.0
		var point := WHEEL_CENTER + Vector3(cos(angle), sin(angle), 0) * WHEEL_RADIUS
		var bar := _csg_cylinder(wheel, "BarraCabine", 0.06, WHEEL_GAP * 2.0, point, steel)
		bar.rotation_degrees.x = 90
		decor_item("Cabine", BOX, Vector3(1.0, 1.0, 1.0), cabin_colors[i % 4], point - Vector3(0, 1.3, 0))
		add_glow(glows, "LampadaRoda", point + Vector3(0, 0, WHEEL_GAP + 0.2), Vector3.ONE * 0.25, Color("fff59d"), true)
	add_light(lights, WHEEL_CENTER + Vector3(0, -4, 3), 12.0, 0.8, Color("ffecb3"))

	decor_item("PlataformaRoda", BOX, Vector3(6, 0.3, 2), Color("90a4ae"), Vector3(12, 0, -10.2))
	item("cone", Vector3(8.4, 0, -8.6))
	item("cone", Vector3(15.6, 0, -8.6))
	item("lixeira_parque", Vector3(16.8, 0, -9.4))
	item("urso", Vector3(12.8, 0.3, -9.6))
	for x in [9.4, 10.6, 13.3]:
		item("poste_fila", Vector3(x, 0, -8.4))


func _add_bumper_cars() -> void:
	var center := Vector3(-12, 0, -12)
	add_floor(map_root.get_node("Floors"), "PistaBateBate", Rect2(-17, -16, 10, 8), Color("263238"), 0.006, false)
	var rail := Color("ffb300")
	wall_x(-16, -17, -7, [], rail, 0.8)
	wall_x(-8, -17, -7, [], rail, 0.8)
	wall_z(-17, -16, -8, [], rail, 0.8)
	wall_z(-7, -16, -8, [[-12.0, 2.0]], rail, 0.8)
	for corner in [Vector2(-17.4, -16.4), Vector2(-6.6, -16.4), Vector2(-17.4, -7.6), Vector2(-6.6, -7.6)]:
		decor_item("ColunaBateBate", CYLINDER, Vector3(0.3, 4.0, 0.3), Color("eceff1"), Vector3(corner.x, 0, corner.y))
	decor_item("TetoBateBate", BOX, Vector3(11.4, 0.2, 9.4), Color("6a1b9a"), Vector3(center.x, 4.0, center.z))
	add_light(lights, Vector3(-14.5, 3.6, -12), 7.0, 1.0, Color("80deea"))
	add_light(lights, Vector3(-9.5, 3.6, -12), 7.0, 1.0, Color("f48fb1"))

	# Carrinhos idênticos (só muda a cor): ótimo para quem se esconde.
	var car_colors := [Color("e53935"), Color("1e88e5"), Color("fdd835"), Color("43a047")]
	var index := 0
	for row in 3:
		for col in 4:
			var at := Vector3(-15.3 + col * 2.2 + rng.randf_range(-0.2, 0.2), 0, -14.6 + row * 2.3 + rng.randf_range(-0.2, 0.2))
			var body: Color = car_colors[index % 4]
			item("carrinho_bate_bate", at, rng.randi_range(0, 11) * 15.0, [body, "212121", "eceff1", "fdd835"])
			index += 1


func _add_game_booths() -> void:
	# Tiro ao alvo: pirâmides de latas.
	var shooting := _booth(-4.0, Color("c62828"))
	decor_item("Prateleira", BOX, Vector3(0.6, 1.2, 3.6), Color("6d4c41"), Vector3(-18.3, 0, shooting))
	for pyramid_z in [shooting - 0.9, shooting + 0.9]:
		for level in 4:
			for i in 4 - level:
				var z: float = pyramid_z + (i - (3 - level) * 0.5) * 0.17
				prop("Lata", CYLINDER, Vector3(0.15, 0.22, 0.15), Color("cfd8dc") if level % 2 == 0 else Color("e53935"),
					Vector3(-18.3, 1.2 + level * 0.22, z))
	item("urso", Vector3(-15.3, 1.0, shooting - 1.4), 90)
	item("urso", Vector3(-15.3, 1.0, shooting - 0.6), 90, ["f48fb1", "fce4ec"])

	# Argolas: garrafas em fileira.
	var rings := _booth(1.0, Color("1565c0"))
	decor_item("Mesa", BOX, Vector3(1.8, 0.8, 3.0), Color("8d6e63"), Vector3(-17.5, 0, rings + 0.1))
	for x in [-18.0, -17.5, -17.0]:
		for i in 6:
			prop("Garrafa", CYLINDER, Vector3(0.12, 0.35, 0.12), Color("43a047"), Vector3(x, 0.8, rings - 1.15 + i * 0.5))
	item("urso", Vector3(-15.3, 1.0, rings - 1.0), 90, ["64b5f6", "e3f2fd"])

	# Pescaria: tanque com patinhos.
	var fishing := _booth(6.0, Color("2e7d32"))
	decor_item("Tanque", BOX, Vector3(2.0, 0.5, 3.2), Color("1e88e5"), Vector3(-17.5, 0, fishing))
	var spots := []
	while spots.size() < 10:
		var spot := Vector3(rng.randf_range(-18.3, -16.7), 0.5, rng.randf_range(fishing - 1.4, fishing + 1.4))
		if spots.all(func(other: Vector3) -> bool: return other.distance_to(spot) > 0.3):
			spots.append(spot)
	for spot: Vector3 in spots:
		prop("Patinho", SPHERE, Vector3(0.2, 0.2, 0.2), Color("ffeb3b"), spot)
	item("urso", Vector3(-15.3, 1.0, fishing - 1.0), 90, ["ffcc80", "fff3e0"])
	item("lixeira_parque", Vector3(-14.0, 0, 9.0))


## Barraca encostada na cerca oeste, aberta para o leste. O balcão deixa uma
## passagem num dos lados. Retorna o z central.
func _booth(center_z: float, color: Color) -> float:
	decor_item("BarracaFundo", BOX, Vector3(0.2, 2.6, 4.0), color, Vector3(-18.7, 0, center_z))
	for side in [-1.9, 1.9]:
		decor_item("BarracaLado", BOX, Vector3(2.0, 2.6, 0.2), color, Vector3(-17.6, 0, center_z + side))
	decor_item("BarracaTeto", BOX, Vector3(4.4, 0.25, 4.4), Color("fafafa"), Vector3(-16.8, 2.6, center_z))
	for side in [-2.1, 2.1]:
		decor_item("BarracaPoste", CYLINDER, Vector3(0.15, 2.6, 0.15), color, Vector3(-14.8, 0, center_z + side))
	decor_item("Balcao", BOX, Vector3(1.0, 1.0, 2.8), Color("fafafa"), Vector3(-15.3, 0, center_z - 0.6))
	add_light(lights, Vector3(-16.5, 2.3, center_z), 5.0, 0.9, Color("ffe0b2"))
	return center_z


func _add_food_court() -> void:
	decor_item("FoodTruck", BOX, Vector3(5.0, 2.6, 2.2), Color("29b6f6"), Vector3(17.2, 0, -2))
	decor_item("FoodTruckToldo", BOX, Vector3(4.0, 0.1, 1.2), Color("fdd835"), Vector3(17.2, 2.2, -0.3))
	_snack_cart("carrinho_pipoca", Vector3(10, 0, -2.5))
	_snack_cart("carrinho_algodao", Vector3(13, 0, 7))
	item("carrinho_sorvete", Vector3(16.2, 0, 7.6), -20)
	item("carrinho_pipoca", Vector3(17.6, 0, 1.6), -90)
	item("balde_pipoca", Vector3(9.6, 0, 1.0))
	item("balde_pipoca", Vector3(16.8, 0, 4.6))

	var umbrella_colors := ["e53935", "fdd835", "1e88e5", "43a047"]
	var tables := [Vector3(11.5, 0, 1.6), Vector3(15, 0, 1.6), Vector3(11.5, 0, 4.6), Vector3(15, 0, 4.6)]
	for i in tables.size():
		var at: Vector3 = tables[i]
		item("mesa_guarda_sol", at, 0, ["eceff1", umbrella_colors[i], "90a4ae"])
		item("cadeira_plastica", at + Vector3(-0.85, 0, 0), 90)
		item("cadeira_plastica", at + Vector3(0.85, 0, 0), -90)
	item("lixeira_parque", Vector3(18.5, 0, 4))
	item("lixeira_parque", Vector3(9, 0, 8.4))
	add_light(lights, Vector3(13.2, 3.5, 3), 9.0, 1.0, Color("ce93d8"))


## Carrinho de comida com balões amarrados (os balões são só decoração).
func _snack_cart(kind: String, at: Vector3) -> void:
	item(kind, at)
	var balloon_colors := [Color("e53935"), Color("1e88e5"), Color("fdd835")]
	for i in 3:
		var offset := Vector3(-0.55 + i * 0.55, 0, -0.15 + (i % 2) * 0.3)
		add_glow(glows, "BalaoFio", at + offset + Vector3(0, 2.4, 0), Vector3(0.02, 0.8, 0.02), Color("eceff1"))
		add_glow(glows, "Balao", at + offset + Vector3(0, 3.05, 0), Vector3.ONE * 0.5, balloon_colors[i], true)


func _add_ball_pit() -> void:
	add_floor(map_root.get_node("Floors"), "PisoBolinhas", Rect2(-17, 12, 6, 5), Color("4fc3f7"), 0.006, false)
	var pad := Color("ff7043")
	wall_x(12, -17, -11, [], pad, 0.6)
	wall_x(17, -17, -11, [], pad, 0.6)
	wall_z(-17, 12, 17, [], pad, 0.6)
	wall_z(-11, 12, 17, [], pad, 0.6)
	var colors := [Color("e53935"), Color("1e88e5"), Color("fdd835"), Color("43a047"), Color("fb8c00")]
	for col in 11:
		for row in 9:
			if rng.randf() < 0.55:
				continue
			var at := Vector3(-16.6 + col * 0.5, 0, 12.4 + row * 0.5)
			prop("Bolinha", SPHERE, Vector3(0.4, 0.4, 0.4), colors[rng.randi() % colors.size()], at)

	# Escorregador: torre com degraus e rampa descendo para o leste.
	var slide := Color("ab47bc")
	wall_box(Vector3(-9, 0.9, 15), Vector3(1.6, 1.8, 1.6), slide)
	for step in 3:
		var height := 1.35 - step * 0.45
		wall_box(Vector3(-9, height * 0.5, 16.1 + step * 0.6), Vector3(1.2, height, 0.6), Color("ce93d8"))
	var run := 3.7
	var drop := 1.8
	wall_box(Vector3(-8.2 + run * 0.5, drop * 0.5 - 0.05, 15), Vector3(Vector2(run, drop).length() + 0.1, 0.15, 1.0),
		Color("fdd835"), Vector3(0, 0, -rad_to_deg(atan2(drop, run))))


func _add_mirror_maze() -> void:
	# Labirinto gerado (busca em profundidade) numa grade de 5 x 4 células de 2 m.
	var origin := Vector2(9, 11)
	var cols := 5
	var rows := 4
	var cell := 2.0
	var height := 2.4
	var mirror := StandardMaterial3D.new()
	mirror.albedo_color = Color("b3e5fc")
	mirror.metallic = 1.0
	mirror.roughness = 0.06
	var frame := Color("b3e5fc")

	var visited := {Vector2i.ZERO: true}
	var opened := {}
	var stack: Array[Vector2i] = [Vector2i.ZERO]
	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next: Vector2i = current + direction
			if next.x >= 0 and next.x < cols and next.y >= 0 and next.y < rows and not visited.has(next):
				options.append(next)
		if options.is_empty():
			stack.pop_back()
			continue
		var chosen := options[rng.randi() % options.size()]
		visited[chosen] = true
		opened[_edge_key(current, chosen)] = true
		stack.append(chosen)

	for c in cols:
		for r in rows:
			var here := Vector2i(c, r)
			if c < cols - 1 and not opened.has(_edge_key(here, here + Vector2i.RIGHT)):
				wall_z(origin.x + (c + 1) * cell, origin.y + r * cell, origin.y + (r + 1) * cell, [], frame, height, 0.0, mirror)
			if r < rows - 1 and not opened.has(_edge_key(here, here + Vector2i.DOWN)):
				wall_x(origin.y + (r + 1) * cell, origin.x + c * cell, origin.x + (c + 1) * cell, [], frame, height, 0.0, mirror)
	var right := origin.x + cols * cell
	var bottom := origin.y + rows * cell
	wall_x(origin.y, origin.x, right, [[origin.x + 3.5 * cell, 1.4]], frame, height, 0.0, mirror)
	wall_x(bottom, origin.x, right, [], frame, height, 0.0, mirror)
	wall_z(origin.x, origin.y, bottom, [[origin.y + 1.5 * cell, 1.4]], frame, height, 0.0, mirror)
	wall_z(right, origin.y, bottom, [], frame, height, 0.0, mirror)

	var maze_items := ["cone", "lixeira_parque", "urso", "medidor_altura", "cone"]
	var cells := [Vector2i(1, 0), Vector2i(4, 1), Vector2i(2, 2), Vector2i(0, 3), Vector2i(3, 3)]
	for i in maze_items.size():
		var at := Vector3(origin.x + (cells[i].x + 0.5) * cell + 0.4, 0, origin.y + (cells[i].y + 0.5) * cell + 0.4)
		item(maze_items[i], at, rng.randf_range(0, 360) if maze_items[i] != "medidor_altura" else 0.0)
	decor_item("PlacaLabirinto", BOX, Vector3(0.1, 0.8, 1.6), Color("4a148c"), Vector3(8.75, 2.8, 14))
	add_glow(glows, "Neon", Vector3(8.68, 2.8, 14), Vector3(0.02, 0.1, 1.4), Color("40c4ff"))


func _add_ghost_train() -> void:
	var dark := Color("311b92")
	wall_x(-19, -6, 6, [], dark, 3.5)
	wall_x(-12, -6, 6, [[-4.0, 1.8], [4.0, 1.8]], dark, 3.5)
	wall_z(-6, -19, -12, [], dark, 3.5)
	wall_z(6, -19, -12, [], dark, 3.5)
	wall_box(Vector3(0, 3.6, -15.5), Vector3(12.4, 0.2, 7.4), Color("1a237e"))
	add_floor(map_root.get_node("Floors"), "PisoTrem", Rect2(-6, -19, 12, 7), Color("212121"), 0.006, false)
	decor_item("LetreiroTrem", BOX, Vector3(6, 1.0, 0.2), Color("4a148c"), Vector3(0, 3.7, -11.8))
	add_glow(glows, "Neon", Vector3(0, 4.2, -11.68), Vector3(5.4, 0.12, 0.04), Color("b388ff"))

	# Trilho em circuito (dois trilhos, sem cruzar nas curvas).
	var rail := Color("757575")
	for z in [-17.9, -13.1]:
		decor_item("Trilho", BOX, Vector3(9.8, 0.05, 0.08), rail, Vector3(0, 0, z))
	for x in [-4.9, 4.9]:
		decor_item("Trilho", BOX, Vector3(0.08, 0.05, 4.6), rail, Vector3(x, 0, -15.5))
	for z in [-17.1, -13.9]:
		decor_item("Trilho", BOX, Vector3(8.2, 0.05, 0.08), rail, Vector3(0, 0, z))
	for x in [-4.1, 4.1]:
		decor_item("Trilho", BOX, Vector3(0.08, 0.05, 3.0), rail, Vector3(x, 0, -15.5))
	for at in [Vector3(-2, 0.05, -13.5), Vector3(1, 0.05, -13.5), Vector3(-1, 0.05, -17.5), Vector3(2.5, 0.05, -17.5)]:
		item("carrinho_trem", at, 90)
	for x in [-3.0, 0.0, 3.0]:
		decor_item("Fantasma", CAPSULE, Vector3(0.6, 1.5, 0.6), Color("eceff1"), Vector3(x, 0, -15.5))
	decor_item("Caixao", BOX, Vector3(0.7, 0.4, 1.8), Color("4e342e"), Vector3(1.5, 0, -15.5))
	for at in [Vector3(-5.5, 0, -18.5), Vector3(5.5, 0, -18.5), Vector3(-5.5, 0, -12.6), Vector3(5.5, 0, -12.6)]:
		prop("Lapide", BOX, Vector3(0.6, 0.8, 0.15), Color("9e9e9e"), at)
	for at in [Vector3(-5.5, 0, -16), Vector3(5.5, 0, -14.5), Vector3(0, 0, -18.6)]:
		prop("Abobora", SPHERE, Vector3(0.45, 0.45, 0.45), Color("fb8c00"), at)
	add_light(lights, Vector3(-3, 2.8, -15.5), 5.0, 1.2, Color("9c27b0"))
	add_light(lights, Vector3(3, 2.8, -15.5), 5.0, 1.2, Color("9c27b0"))
	add_light(lights, Vector3(0, 2.8, -13), 4.0, 0.8, Color("76ff03"))


func _add_trees_and_lamps() -> void:
	var round_trees := [Vector3(-18.5, 0, -18.5), Vector3(8, 0, -18.5), Vector3(-18.5, 0, 10), Vector3(-13, 0, -3)]
	for at: Vector3 in round_trees:
		decor_item("Tronco", CYLINDER, Vector3(0.35, 2.0, 0.35), Color("6d4c41"), at)
		decor_item("Copa", SPHERE, Vector3(2.2, 2.2, 2.2), Color("388e3c"), at + Vector3(0, 2.0, 0))
	var pines := [Vector3(-8, 0, -18.5), Vector3(18.5, 0, -18.5), Vector3(18.5, 0, 9.6), Vector3(-10, 0, 18.5), Vector3(6.5, 0, 10)]
	for at: Vector3 in pines:
		decor_item("Tronco", CYLINDER, Vector3(0.3, 1.0, 0.3), Color("6d4c41"), at)
		decor_item("Pinheiro", CONE, Vector3(2.0, 3.0, 2.0), Color("2e7d32"), at + Vector3(0, 1.0, 0))

	var lamps := [
		Vector3(-2.6, 0, 9), Vector3(2.6, 0, 9), Vector3(-2.6, 0, 13), Vector3(2.6, 0, 13),
		Vector3(-7.5, 0, -7.5), Vector3(7.5, 0, -7.5), Vector3(-7.5, 0, 7.5), Vector3(7.5, 0, 7.5),
		Vector3(-12, 0, 3), Vector3(6, 0, -10),
	]
	for at: Vector3 in lamps:
		decor_item("Poste", CYLINDER, Vector3(0.15, 3.6, 0.15), Color("37474f"), at)
		add_glow(glows, "LampadaPoste", at + Vector3(0, 3.85, 0), Vector3.ONE * 0.5, LAMP, true)
		add_light(lights, at + Vector3(0, 3.6, 0), 8.0, 1.1, LAMP)


# --- Ampliação norte -------------------------------------------------------------

func _add_stage() -> void:
	var purple := Color("4a148c")
	var top := 1.0
	wall_box(Vector3(-12, top * 0.5, -35.5), Vector3(12, top, 4.0), Color("37474f"))
	wall_box(Vector3(-12, 3.0, -37.4), Vector3(12, 4.0, 0.2), purple)
	wall_box(Vector3(-12, 5.1, -35.5), Vector3(12.4, 0.2, 4.4), purple)
	for x in [-17.9, -6.1]:
		wall_box(Vector3(x, 3.0, -33.7), Vector3(0.25, 4.0, 0.25), Color("212121"))
	for x in [-17.0, -7.0]:
		stairs(Vector3(x, 0.0, -31.9), Vector3(x, top, -33.5), 1.2, Color("455a64"))
	for x in [-17.2, -16.4, -7.6, -6.8]:
		item("caixa_som", Vector3(x, top, -36.8))
	item("bateria", Vector3(-12, top, -36.2))
	for x in [-14.5, -9.5]:
		item("caixa_ferramentas", Vector3(x, top, -37.0), 0, ["212121", "616161"])
	add_glow(glows, "NeonPalco", Vector3(-12, 4.6, -37.25), Vector3(10, 0.15, 0.05), Color("e040fb"))
	add_light(lights, Vector3(-14, 4.6, -34.5), 7.0, 1.2, Color("e040fb"))
	add_light(lights, Vector3(-10, 4.6, -34.5), 7.0, 1.2, Color("40c4ff"))
	# Plateia: fileiras de cadeiras plásticas iguais, viradas para o palco.
	for z in [-31.0, -29.8, -28.6, -27.4]:
		for x in [-15.0, -14.0, -13.0, -11.0, -10.0, -9.0]:
			item("cadeira_plastica", Vector3(x, 0, z), 180)
	item("lixeira_parque", Vector3(-18.6, 0, -24.8))
	item("lixeira_parque", Vector3(-5.4, 0, -24.8))
	item("totem_mapa", Vector3(-4.6, 0, -27.0), -90)


func _add_lake() -> void:
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("1e88e5")
	water.metallic = 0.4
	water.roughness = 0.1
	var surface := CSGBox3D.new()
	surface.name = "Agua"
	surface.size = Vector3(18, 0.04, 12)
	surface.position = Vector3(6, 0.02, -30)
	surface.material = water
	map_root.get_node("Floors").add_child(surface)
	var rail := Color("8d6e63")
	wall_x(-24, -3, 15, [[6, 2.2]], rail, 0.5)
	wall_x(-36, -3, 15, [], rail, 0.5)
	wall_z(-3, -36, -24, [], rail, 0.5)
	wall_z(15, -36, -24, [], rail, 0.5)
	# Píer com pedalinhos atracados dos dois lados.
	wall_box(Vector3(6, 0.15, -29.0), Vector3(2.2, 0.3, 8.4), Color("a1887f"))
	stairs(Vector3(6, 0, -23.4), Vector3(6, 0.3, -24.8), 2.0, Color("8d6e63"))
	var colors := [["fafafa", "ff9800", "1e88e5", "212121"], ["fafafa", "ff9800", "e53935", "212121"],
		["fafafa", "ff9800", "43a047", "212121"]]
	var index := 0
	for x in [3.9, 8.1]:
		for z in [-27.0, -29.6, -32.2]:
			item("pedalinho", Vector3(x, 0, z), 0, colors[index % colors.size()])
			index += 1
	item("pedalinho", Vector3(11.5, 0, -30.5), 40, colors[0])
	item("pedalinho", Vector3(0.5, 0, -33.5), -30, colors[1])
	add_light(lights, Vector3(6, 3.5, -30), 10.0, 0.7, LAMP)
	# Piquenique entre o lago e a montanha-russa, e na margem sul.
	for z in [-25.5, -28.5, -31.5, -34.5]:
		item("mesa_piquenique", Vector3(17.5, 0, z), 90)
	item("mesa_piquenique", Vector3(-0.5, 0, -22.9))
	item("mesa_piquenique", Vector3(11.0, 0, -22.9))
	item("lixeira_parque", Vector3(13.4, 0, -22.9))


func _add_roller_coaster() -> void:
	# Trilho (só visual) num circuito com subida a leste e queda ao norte; pilares
	# com colisão formam uma área sombria embaixo.
	var points := [
		Vector3(24, 1.2, -25), Vector3(34, 1.2, -25), Vector3(35.5, 1.6, -26.5), Vector3(35.5, 8.0, -34),
		Vector3(34, 8.0, -35.5), Vector3(29, 2.5, -35.5), Vector3(26, 4.5, -35.5), Vector3(23.5, 4.0, -35),
		Vector3(22.5, 3.0, -33), Vector3(22.5, 1.6, -27), Vector3(24, 1.2, -25),
	]
	var track := add_group("MontanhaRussa")
	var red := PropBuilder.get_material(Color("d32f2f"))
	var steel := PropBuilder.get_material(Color("eceff1"))
	var pillar := Color("b0bec5")
	var pillar_count := 0
	for i in points.size() - 1:
		var a: Vector3 = points[i]
		var b: Vector3 = points[i + 1]
		var pieces := maxi(1, ceili(a.distance_to(b) / 1.5))
		for k in pieces:
			var p0 := a.lerp(b, float(k) / pieces)
			var p1 := a.lerp(b, float(k + 1) / pieces)
			_beam(track, p0, p1, Vector3(1.0, 0.15, 0), red)
			for side in [-0.42, 0.42]:
				var offset: Vector3 = (p1 - p0).cross(Vector3.UP).normalized() * side + Vector3.UP * 0.12
				_beam(track, p0 + offset, p1 + offset, Vector3(0.08, 0.08, 0), steel)
			# Pilar a cada pedaço, fora da estação.
			if p1.y > 1.5 and i > 0:
				pillar_count += 1
				wall_box(Vector3(p1.x, (p1.y - 0.1) * 0.5, p1.z), Vector3(0.3, p1.y - 0.1, 0.3), pillar)
	# Estação com teto, escada e carrinhos parados no trilho.
	wall_box(Vector3(29, 0.6, -24.3), Vector3(11, 1.2, 2.6), Color("78909c"))
	wall_box(Vector3(29, 4.0, -24.3), Vector3(11.4, 0.2, 3.0), Color("1565c0"))
	for x in [23.6, 34.4]:
		wall_box(Vector3(x, 2.6, -23.1), Vector3(0.25, 2.6, 0.25), Color("212121"))
	stairs(Vector3(29, 0.0, -20.6), Vector3(29, 1.2, -23.0), 1.6, Color("455a64"))
	var car_colors := [["1e88e5", "fdd835", "212121"], ["e53935", "fdd835", "212121"], ["43a047", "fdd835", "212121"]]
	for i in 5:
		item("carrinho_montanha", Vector3(25.5 + i * 1.8, 1.2, -25.0), 90, car_colors[i % 3])
	add_glow(glows, "NeonMontanha", Vector3(29, 4.2, -22.75), Vector3(9, 0.15, 0.05), Color("ffeb3b"))
	add_light(lights, Vector3(29, 3.5, -24.3), 7.0, 1.0, LAMP)
	add_light(lights, Vector3(29, 3.0, -30.5), 9.0, 0.6, Color("ffab91"))
	# Fila com postes e medidor de altura.
	for x in [23.3, 24.5, 25.7, 26.9]:
		item("poste_fila", Vector3(x, 0, -20.8))
	item("medidor_altura", Vector3(30.6, 0, -21.3))
	# Embaixo do trilho.
	item("lixeira_parque", Vector3(25.5, 0, -27.5))
	item("cone", Vector3(31.5, 0, -33.5))
	item("cone", Vector3(32.1, 0, -33.6))
	item("caixa_ferramentas", Vector3(27.5, 0, -33.2), 30, ["fbc02d", "212121"])
	item("banco_praca", Vector3(28.5, 0, -27.8))
	item("carrinho_montanha", Vector3(33.0, 0, -29.0), 10, car_colors[1])


func _add_new_paths_decor() -> void:
	# Postes de luz ao longo das ruas novas e árvores.
	for at in [Vector3(-15, 0, -19.5), Vector3(-8, 0, -22.6), Vector3(10, 0, -19.5), Vector3(21.6, 0, -19.5),
			Vector3(21.6, 0, -8.4), Vector3(21.6, 0, 8.5), Vector3(18.4, 0, -30), Vector3(18.4, 0, 18.5)]:
		decor_item("Poste", CYLINDER, Vector3(0.15, 3.6, 0.15), Color("37474f"), at)
		add_glow(glows, "LampadaPoste", at + Vector3(0, 3.85, 0), Vector3.ONE * 0.5, LAMP, true)
		add_light(lights, at + Vector3(0, 3.6, 0), 8.0, 1.1, LAMP)
	for at in [Vector3(16, 0, -35.5), Vector3(-18.4, 0, -30), Vector3(-4.4, 0, -35.4), Vector3(35, 0, -21)]:
		decor_item("Tronco", CYLINDER, Vector3(0.35, 2.0, 0.35), Color("6d4c41"), at)
		decor_item("Copa", SPHERE, Vector3(2.0, 2.0, 2.0), Color("388e3c"), at + Vector3(0, 2.0, 0))


# --- Ampliação leste ---------------------------------------------------------------

func _add_teacups() -> void:
	var center := Vector3(25.5, 0, -14)
	# Plataforma baixinha (4 cm), para dar para subir sem degrau.
	decor_item("PlataformaXicaras", CYLINDER, Vector3(8.4, 0.04, 8.4), Color("ce93d8"), center)
	var y := 0.04
	decor_item("Bule", SPHERE, Vector3(1.6, 1.6, 1.6), Color("fafafa"), center + Vector3(0, y, 0))
	decor_item("BuleTampa", CONE, Vector3(0.8, 0.6, 0.8), Color("ad1457"), center + Vector3(0, y + 1.55, 0))
	var colors := [["f48fb1", "fafafa", "ad1457"], ["81d4fa", "fafafa", "0277bd"], ["fff59d", "fafafa", "f9a825"],
		["a5d6a7", "fafafa", "2e7d32"], ["ce93d8", "fafafa", "6a1b9a"], ["ffab91", "fafafa", "d84315"]]
	for i in 6:
		var angle := TAU * i / 6.0
		item("xicara", center + Vector3(cos(angle) * 2.9, y, sin(angle) * 2.9), (i % 4) * 90.0, colors[i])
	add_glow(glows, "LampadaXicara", center + Vector3(0, 3.0, 0), Vector3.ONE * 0.4, Color("fff59d"), true)
	add_light(lights, center + Vector3(0, 3.5, 0), 7.0, 1.0, Color("f8bbd0"))
	item("medidor_altura", Vector3(22.0, 0, -19.4), 90)
	item("lixeira_parque", Vector3(22.0, 0, -9.2))


func _add_mini_golf() -> void:
	add_floor(map_root.get_node("Floors"), "Grama Golfe", Rect2(30, -19, 7, 10), Color("2e7d32"), 0.006, false)
	var border := Color("fafafa")
	wall_x(-19, 30, 37, [], border, 0.25)
	wall_x(-9, 30, 37, [], border, 0.25)
	wall_z(30, -19, -9, [[-14, 2.0]], border, 0.25)
	wall_z(37, -19, -9, [], border, 0.25)
	wall_x(-14, 32, 37, [], border, 0.25)
	# Moinho (com pás só visuais) e castelinho.
	var mill := Vector3(34.0, 0, -16.8)
	decor_item("Moinho", BOX, Vector3(1.4, 2.2, 1.4), Color("d7ccc8"), mill)
	decor_item("MoinhoTeto", CONE, Vector3(1.9, 1.0, 1.9), Color("c62828"), mill + Vector3(0, 2.2, 0))
	var blades := add_group("PasMoinho")
	for angle in [45.0, -45.0]:
		var blade := CSGBox3D.new()
		blade.name = "Pa%d" % (blades.get_child_count() + 1)
		blade.size = Vector3(2.6, 0.25, 0.05)
		blade.position = mill + Vector3(0, 1.7, 0.75)
		blade.rotation_degrees.z = angle
		blade.material = PropBuilder.get_material(Color("8d6e63"))
		blades.add_child(blade)
	var castle := Vector3(34.4, 0, -11.4)
	decor_item("Castelo", BOX, Vector3(1.6, 1.2, 1.6), Color("bcaaa4"), castle)
	for corner in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8)]:
		decor_item("Torre", CYLINDER, Vector3(0.45, 1.7, 0.45), Color("a1887f"), castle + corner)
		decor_item("TorreTeto", CONE, Vector3(0.6, 0.5, 0.6), Color("1565c0"), castle + corner + Vector3(0, 1.7, 0))
	for at in [Vector3(31.0, 0, -17.8), Vector3(31.0, 0, -10.2)]:
		decor_item("Bandeira", CYLINDER, Vector3(0.03, 1.2, 0.03), Color("eceff1"), at)
		decor_item("BandeiraPano", BOX, Vector3(0.02, 0.25, 0.35), Color("e53935"), at + Vector3(0, 0.95, 0.18))
	for at in [Vector3(32.5, 0, -18.2), Vector3(35.6, 0, -15.0), Vector3(32.2, 0, -12.6), Vector3(33.0, 0, -9.7),
			Vector3(36.2, 0, -9.8)]:
		prop("BolaGolfe", SPHERE, Vector3(0.12, 0.12, 0.12), Color("fafafa"), at)
	item("cone", Vector3(32.6, 0, -15.2))
	item("cone", Vector3(35.6, 0, -13.0))
	item("banco_praca", Vector3(28.3, 0, -9.6), 180)
	item("lixeira_parque", Vector3(29.6, 0, -19.6))


func _add_arcade() -> void:
	var wall := Color("311b92")
	wall_x(-7, 22, 36, [], wall, 3.6)
	wall_x(7, 22, 36, [], wall, 3.6)
	wall_z(22, -7, 7, [[0, 2.4, 0.0, 2.6]], wall, 3.6)
	wall_z(36, -7, 7, [], wall, 3.6)
	wall_box(Vector3(29, 3.7, 0), Vector3(14.2, 0.2, 14.2), Color("1a237e"))
	add_ceiling(map_root.get_node("Floors"), "ForroFliperama", Rect2(22, -7, 14, 14), 3.58, Color("212121"))
	add_floor(map_root.get_node("Floors"), "CarpeteFliperama", Rect2(22, -7, 14, 14), Color("4527a0"), 0.006, false)
	var cabinet_colors := [["3949ab", "212121", "40c4ff", "e53935"], ["c62828", "212121", "ffeb3b", "40c4ff"],
		["2e7d32", "212121", "e040fb", "fdd835"]]
	for i in 8:
		var x := 23.0 + i * 0.8
		wall_item("fliperama", "N", -7, x, 0.0, false, cabinet_colors[i % 3])
		wall_item("fliperama", "S", 7, x, 0.0, false, cabinet_colors[(i + 1) % 3])
	for i in 6:
		var x := 25.0 + i * 0.8
		item("fliperama", Vector3(x, 0, -0.45), 180, cabinet_colors[(i + 2) % 3])
		item("fliperama", Vector3(x, 0, 0.45), 0, cabinet_colors[i % 3])
	item("air_hockey", Vector3(32.5, 0, -3.0), 90)
	item("air_hockey", Vector3(32.5, 0, 3.0), 90, ["e53935", "eceff1", "1e88e5", "212121"])
	for z in [-5.5, -4.3, 4.3, 5.5]:
		wall_item("maquina_pelucia", "E", 36, z, 0.0, false,
			["ff4081" if z < 0 else "00bcd4", "b3e5fc", "fdd835", "8d6e63"])
	item("lixeira", Vector3(22.5, 0, -2.5))
	item("lixeira", Vector3(22.5, 0, 2.5))
	item("banqueta", Vector3(30.8, 0, -5.4))
	item("banqueta", Vector3(30.8, 0, 5.4))
	for z in [-6.85, 6.85]:
		add_glow(glows, "NeonFliperama", Vector3(29, 3.2, z), Vector3(13, 0.1, 0.04), Color("e040fb") if z < 0 else Color("40c4ff"))
	add_glow(glows, "LetreiroFliperama", Vector3(21.85, 3.0, 0), Vector3(0.06, 0.4, 3.0), Color("ffeb3b"))
	add_light(lights, Vector3(26, 3.0, 0), 8.0, 1.2, Color("b388ff"))
	add_light(lights, Vector3(32, 3.0, 0), 8.0, 1.2, Color("80d8ff"))


func _add_prize_shop() -> void:
	var color := Color("ff7043")
	wall_x(9, 22, 30, [], color, 3.0)
	wall_x(19, 22, 30, [], color, 3.0)
	wall_z(30, 9, 19, [], color, 3.0)
	wall_box(Vector3(26, 3.1, 14), Vector3(8.4, 0.2, 10.4), Color("fafafa"))
	decor_item("BalcaoPremios", BOX, Vector3(0.8, 1.0, 5.0), Color("fafafa"), Vector3(22.5, 0, 12.0))
	add_glow(glows, "LetreiroPremios", Vector3(21.9, 2.6, 14), Vector3(0.06, 0.35, 4.0), Color("ff4081"))
	var bear_colors := [["8d6e63", "efebe9"], ["f48fb1", "fce4ec"], ["64b5f6", "e3f2fd"], ["fafafa", "ffcdd2"],
		["ba68c8", "f3e5f5"], ["ffd54f", "fff8e1"]]
	var index := 0
	for z in [10.0, 11.4, 12.8, 14.2, 15.6, 17.0]:
		wall_item("urso_gigante", "E", 30, z, 0.0, false, bear_colors[index % bear_colors.size()])
		index += 1
	for x in [23.6, 25.0, 26.4, 27.8]:
		wall_item("urso_gigante", "N", 9, x, 0.0, false, bear_colors[index % bear_colors.size()])
		index += 1
	for z in [10.2, 11.2, 13.8]:
		item("ursinho", Vector3(22.5, 1.0, z), 90, bear_colors[int(z) % bear_colors.size()])
	item("balde_pipoca", Vector3(24.5, 0, 17.8))
	item("balde_pipoca", Vector3(25.6, 0, 17.9))
	add_light(lights, Vector3(26, 2.6, 14), 7.0, 1.0, Color("ffe0b2"))


func _add_restrooms() -> void:
	var color := Color("80cbc4")
	wall_x(9, 31, 37, [], color, 3.0)
	wall_x(19, 31, 37, [], color, 3.0)
	wall_x(14, 31, 37, [], color, 3.0)
	wall_z(31, 9, 19, [door(11.5), door(16.5)], color, 3.0)
	wall_z(37, 9, 19, [], color, 3.0)
	wall_box(Vector3(34, 3.1, 14), Vector3(6.4, 0.2, 10.4), Color("eceff1"))
	add_ceiling(map_root.get_node("Floors"), "ForroBanheiros", Rect2(31, 9, 6, 10), 3.0, Color("fafafa"))
	for half in [[9.0, 1.0], [19.0, -1.0]]:
		var wall_z_pos: float = half[0]
		var dir: float = half[1]
		for k in [1.0, 2.6]:
			wall_item("vaso_sanitario", "E", 37, wall_z_pos + dir * k, 0.0)
		wall_box(Vector3(36.3, 1.0, wall_z_pos + dir * 1.8), Vector3(1.3, 2.0, 0.05), Color("4db6ac"))
		wall_item("pia_gabinete", "N" if dir > 0 else "S", wall_z_pos, 32.0, 0.0)
		item("lixeira", Vector3(32.8, 0, wall_z_pos + dir * 4.4))
	add_glow(glows, "PlacaBanheiro", Vector3(30.9, 2.6, 14), Vector3(0.05, 0.4, 1.0), Color("e0f7fa"))
	add_light(lights, Vector3(34, 2.6, 11.5), 5.0, 0.8)
	add_light(lights, Vector3(34, 2.6, 16.5), 5.0, 0.8)


## Viga (caixa) ligando `a` a `b`; `size.z` é ignorado (vira o comprimento).
func _beam(parent: Node, a: Vector3, b: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, a.distance_to(b) + 0.02)
	mesh.material = material
	var beam := MeshInstance3D.new()
	beam.name = "Viga%d" % (parent.get_child_count() + 1)
	beam.mesh = mesh
	beam.transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5)
	parent.add_child(beam)


# --- Auxiliares --------------------------------------------------------------------

func _csg_cylinder(parent: Node, cylinder_name: String, radius: float, height: float, at: Vector3,
		material: Material) -> CSGCylinder3D:
	var cylinder := CSGCylinder3D.new()
	cylinder.name = cylinder_name
	cylinder.radius = radius
	cylinder.height = height
	cylinder.sides = 32
	cylinder.position = at
	cylinder.material = material
	parent.add_child(cylinder)
	return cylinder


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var low := a if a.x < b.x or (a.x == b.x and a.y < b.y) else b
	var high := b if low == a else a
	return "%s|%s" % [low, high]
