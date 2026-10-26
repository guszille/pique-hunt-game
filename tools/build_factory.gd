extends "res://tools/map_builder.gd"
## Gera res://scenes/maps/factory.tscn (mapa "Fábrica").
## Uso: godot --headless --path . -s res://tools/build_factory.gd
##
## Planta (x = leste, z = sul):
##   Galpão (x -15..15, z -11..11, 7 m): estoque com prateleiras (NO), esteiras no
##     meio, barris (NE), oficina (L), vestiário (O), docas (SO) e mezanino com
##     escritório (SE). Passarelas a 4,5 m nas paredes norte e leste.
##   Anexo oeste (x -27..-15): refeitório, corredor e escritório administrativo;
##     casa de máquinas no subsolo (y = -3,2).
##   Anexos norte (z -19..-11): almoxarifado (oeste) e câmara fria (leste).
##   Pátio (z 11..30): contêineres empilhados, caminhão-baú aberto, bobinas, guarita.

const CRATE_COLOR := Color("c8a165")
const MEZZANINE_HEIGHT := 3.0
const CATWALK_HEIGHT := 4.5
const ANNEX_HEIGHT := 3.2
const STORE_HEIGHT := 3.6
const BASEMENT := -3.2

const METAL := Color("a7b4bb")
const PILLAR := Color("607d8b")
const RAIL := Color("fbc02d")
const GRATE := Color("78909c")
const ANNEX_WALL := Color("e0e0e0")
const BASEMENT_WALL := Color("8d8d8d")
const CEILING := Color("eceff1")

## Vão da escada do subsolo no corredor do anexo.
const BASEMENT_STAIR_HOLE := Rect2(-22.4, -1.4, 4.8, 1.1)

var rng := RandomNumberGenerator.new()
var lights: Node3D


func _init() -> void:
	out_path = "res://scenes/maps/factory.tscn"
	map_name = "Fábrica"
	root_name = "Factory"
	wall_height = 7.0
	rng.seed = 2026


func _build() -> void:
	var env := add_environment(Color("5b7fa6"), Color("c9d6e3"), 0.7, 1.0)
	var sky_material := env.sky.sky_material as ProceduralSkyMaterial
	sky_material.ground_horizon_color = Color("a9b0a4")
	sky_material.ground_bottom_color = Color("8a8f86")
	_add_floors()
	lights = add_group("Luzes")
	_add_hall_structure()
	_add_catwalks()
	_add_annexes()
	_add_fence()
	add_content_groups()
	_add_storage()
	_add_barrels()
	_add_production_line()
	_add_workshop()
	_add_lockers()
	_add_docks()
	_add_center()
	_add_mezzanine()
	_add_canteen()
	_add_admin_office()
	_add_machine_room()
	_add_warehouse()
	_add_cold_room()
	_add_yard()
	_add_lights()
	add_markers([
		Vector3(-12, 0.1, -4.5), Vector3(-4.5, 0.1, -5.0), Vector3(3, 0.1, -7), Vector3(10, 0.1, -4.5),
		Vector3(12.6, 0.1, -1.2), Vector3(2, 0.1, 4), Vector3(-6, 0.1, 0), Vector3(-10, 0.1, 5.0),
		Vector3(12, MEZZANINE_HEIGHT + 0.1, 7), Vector3(-5, CATWALK_HEIGHT + 0.1, -10.2),
		Vector3(-18, 0.1, -5), Vector3(-19.3, 0.1, 2.6), Vector3(-20, BASEMENT + 0.1, 2.5),
		Vector3(-6, 0.1, -16.2), Vector3(9, 0.1, -15), Vector3(-2, 0.1, 18), Vector3(9, 0.1, 22),
		Vector3(-20.5, 0.1, -16.5),
	], Vector3(35, 0.1, 0), Vector3(2, 0.1, 14))


# --- Estrutura -----------------------------------------------------------------

func _add_floors() -> void:
	var floors := add_group("Floors")
	add_slab(floors, "Grama", Rect2(-70, -70, 140, 140), -0.02, Color("6a994e"), [Rect2(-27, -11, 12, 22)])
	add_floor(floors, "Patio", Rect2(-29, 11, 46, 19), Color("616161"), 0.0)
	add_floor(floors, "Fundos", Rect2(-29, -21, 46, 2), Color("757575"), 0.0)
	add_floor(floors, "Sucata", Rect2(-29, -19, 14, 8), Color("757575"), 0.0)
	add_floor(floors, "Concreto", Rect2(-15, -11, 30, 22), Color("7a7f84"))
	add_floor(floors, "PisoRefeitorio", Rect2(-27, -11, 12, 9.5), Color("cfd8dc"))
	add_slab(floors, "PisoCorredor", Rect2(-27, -1.5, 12, 3), 0.0, Color("b0bec5"), [BASEMENT_STAIR_HOLE])
	add_floor(floors, "PisoEscritorio", Rect2(-27, 1.5, 12, 9.5), Color("d7ccc8"))
	add_floor(floors, "PisoAlmoxarifado", Rect2(-15, -19, 18, 8), Color("8d9499"))
	add_floor(floors, "PisoCamaraFria", Rect2(3, -19, 12, 8), Color("e3f2fd"))
	add_floor(floors, "PisoSubsolo", Rect2(-27, -11, 12, 22), Color("6d6d6d"), BASEMENT)
	add_seeker_cage(floors, Vector3(35, 0, 0))

	# Faixas de segurança pintadas no chão (sem colisão).
	var stripes := add_group("Faixas", floors)
	var yellow := Color("fdd835")
	for z in [-1.75, 1.75]:
		add_floor(stripes, "FaixaCorredor", Rect2(-9, z - 0.05, 14, 0.1), yellow, 0.005, false)
	for rect in [Rect2(-14.6, 4.4, 11, 0.1), Rect2(-3.7, 4.4, 0.1, 6.5)]:
		add_floor(stripes, "FaixaDocas", rect, yellow, 0.005, false)
	add_floor(stripes, "FaixaEstoque", Rect2(-13.4, -6.0, 9.0, 0.1), yellow, 0.005, false)

	var ceilings := add_group("Ceilings")
	add_ceiling(ceilings, "ForroAnexo", Rect2(-27, -11, 12, 22), ANNEX_HEIGHT - 0.2, CEILING)
	add_ceiling(ceilings, "ForroSubsolo", Rect2(-27, -11, 12, 22), -0.2, Color("9e9e9e"), [BASEMENT_STAIR_HOLE])
	add_ceiling(ceilings, "ForroAnexoNorte", Rect2(-15, -19, 30, 8), STORE_HEIGHT - 0.2, CEILING)


func _add_hall_structure() -> void:
	# Portas: almoxarifado e câmara fria (norte), anexo (oeste), doca e porta de pessoas (sul).
	wall_x(-11, -15, 15, [[-1, 2.0, 0.0, 2.6], [10, 2.0, 0.0, 2.6]], METAL)
	wall_x(11, -15, 15, [[-10, 4.6, 0.0, 4.2], door(4, DOOR, 2.4)], METAL)
	wall_z(-15, -11, 11, [[0, 2.0, 0.0, 2.6]], METAL)
	wall_z(15, -11, 11, [], METAL)

	for at in [Vector2(-7.5, -5.5), Vector2(0, -5.5), Vector2(7.5, -5.5), Vector2(-7.5, 5.5), Vector2(0, 5.5)]:
		wall_box(Vector3(at.x, wall_height * 0.5, at.y), Vector3(0.5, wall_height, 0.5), PILLAR)

	# Mezanino (x 7..15, z 5..11) com pilares, guarda-corpo e rampa de acesso.
	wall_box(Vector3(11, MEZZANINE_HEIGHT - 0.15, 8), Vector3(8, 0.3, 6), GRATE)
	for at in [Vector2(7.25, 5.25), Vector2(11, 5.25)]:
		wall_box(Vector3(at.x, (MEZZANINE_HEIGHT - 0.3) * 0.5, at.y), Vector3(0.4, MEZZANINE_HEIGHT - 0.3, 0.4), PILLAR)
	wall_x(5, 7, 15, [[14.2, 1.2]], RAIL, 1.0, MEZZANINE_HEIGHT)
	wall_z(7, 5, 8.8, [], RAIL, 1.0, MEZZANINE_HEIGHT)
	var ramp_run := 7.0
	var slope := atan2(MEZZANINE_HEIGHT, ramp_run)
	wall_box(Vector3(ramp_run * 0.5, MEZZANINE_HEIGHT * 0.5 - 0.05, 9.8),
		Vector3(ramp_run / cos(slope) + 0.1, 0.2, 2.0), GRATE, Vector3(0, 0, rad_to_deg(slope)))

	# Treliças do telhado e um teto escuro (só visual).
	var roof := add_group("Telhado")
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		var beam := CSGBox3D.new()
		beam.name = "Trelica%d" % (roof.get_child_count() + 1)
		beam.size = Vector3(0.3, 0.5, 22.4)
		beam.position = Vector3(x, wall_height - 0.25, 0)
		beam.material = PropBuilder.get_material(Color("546e7a"))
		roof.add_child(beam)
	wall_box(Vector3(0, wall_height + 0.1, 0), Vector3(30.4, 0.2, 22.4), Color("455a64"))


func _add_catwalks() -> void:
	# Passarela norte (por cima das prateleiras) e leste (por cima da oficina).
	var t := 0.15
	var y := CATWALK_HEIGHT - t * 0.5
	wall_box(Vector3(0, y, -10.2), Vector3(29.8, t, 1.4), GRATE)
	wall_box(Vector3(14.2, y, -3.45), Vector3(1.4, t, 12.1), GRATE)
	wall_x(-9.5, -13.6, 13.5, [], RAIL, 1.0, CATWALK_HEIGHT)
	wall_z(13.5, -9.5, 2.6, [], RAIL, 1.0, CATWALK_HEIGHT)
	# Escadas: do chão (parede oeste) e do mezanino (canto leste).
	stairs(Vector3(-14.2, 0.0, -2.6), Vector3(-14.2, CATWALK_HEIGHT, -9.5), 1.2, GRATE)
	stairs(Vector3(14.2, MEZZANINE_HEIGHT, 5.2), Vector3(14.2, CATWALK_HEIGHT, 2.6), 1.2, GRATE)
	wall_box(Vector3(14.2, MEZZANINE_HEIGHT * 0.5, 3.0), Vector3(0.3, MEZZANINE_HEIGHT, 0.3), PILLAR)


func _add_annexes() -> void:
	# Anexo oeste: refeitório | corredor (com a escada do subsolo) | escritório.
	var h := ANNEX_HEIGHT
	wall_x(-11, -27, -15, [[-21, 2.0, 1.0, 2.2]], ANNEX_WALL, h)
	wall_x(11, -27, -15, [[-21, 2.0, 1.0, 2.2]], ANNEX_WALL, h)
	wall_z(-27, -11, 11, [door(0, MAIN_DOOR, 2.4), [-6, 1.6, 1.0, 2.2], [6, 1.6, 1.0, 2.2]], ANNEX_WALL, h)
	wall_x(-1.5, -27, -15, [door(-24.6)], ANNEX_WALL, 3.0)
	wall_x(1.5, -27, -15, [door(-21)], ANNEX_WALL, 3.0)
	wall_box(Vector3(-21, h - 0.1, 0), Vector3(12.2, 0.2, 22.2), Color("9e9e9e"))
	var hole := BASEMENT_STAIR_HOLE
	var rail := WALL_THICKNESS * 0.5
	wall_x(hole.end.y + rail, hole.position.x - rail, hole.end.x, [], ANNEX_WALL, 1.0)
	wall_z(hole.position.x - rail, hole.position.y, hole.end.y + rail, [], ANNEX_WALL, 1.0)
	stairs(Vector3(hole.position.x, BASEMENT, hole.get_center().y), Vector3(hole.end.x, 0.0, hole.get_center().y),
		hole.size.y, Color("616161"))

	# Subsolo (casa de máquinas) em três salas.
	var base := BASEMENT
	wall_x(-11, -27, -15, [], BASEMENT_WALL, 3.0, base)
	wall_x(11, -27, -15, [], BASEMENT_WALL, 3.0, base)
	wall_z(-27, -11, 11, [], BASEMENT_WALL, 3.0, base)
	wall_z(-15, -11, 11, [], BASEMENT_WALL, 3.0, base)
	wall_x(-4, -27, -15, [door(-18, MAIN_DOOR)], BASEMENT_WALL, 3.0, base)
	wall_x(4, -27, -15, [door(-24, MAIN_DOOR)], BASEMENT_WALL, 3.0, base)

	# Anexos norte: almoxarifado | câmara fria.
	var sh := STORE_HEIGHT
	wall_x(-19, -15, 15, [], ANNEX_WALL, sh)
	wall_z(-15, -19, -11, [], ANNEX_WALL, sh)
	wall_z(15, -19, -11, [], ANNEX_WALL, sh)
	wall_z(3, -19, -11, [], Color("bbdefb"), sh)
	wall_box(Vector3(0, sh - 0.1, -15), Vector3(30.2, 0.2, 8.2), Color("9e9e9e"))
	# Cortina de tiras na porta da câmara fria (só visual).
	var curtain := add_group("Cortina")
	var strip := StandardMaterial3D.new()
	strip.albedo_color = Color(0.85, 0.95, 1.0, 0.45)
	strip.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 8:
		var box := CSGBox3D.new()
		box.name = "Tira%d" % (i + 1)
		box.size = Vector3(0.22, 2.5, 0.02)
		box.position = Vector3(9.12 + i * 0.25, 1.3, -11.2)
		box.material = strip
		curtain.add_child(box)


func _add_fence() -> void:
	var fence := Color("cfd8dc")
	wall_x(-21, -29, 17, [], fence, 2.0)
	wall_x(30, -29, 17, [], fence, 2.0)
	wall_z(-29, -21, 30, [], fence, 2.0)
	wall_z(17, -21, 30, [], fence, 2.0)


# --- Galpão ----------------------------------------------------------------------

func _add_storage() -> void:
	# Duas prateleiras industriais de 3 níveis cheias de caixas.
	for rack_z in [-10.3, -7.3]:
		_rack(Vector3(-9, 0, rack_z), 8.6)
	for y in [0.0, 0.6, 1.2]:
		item("caixa_madeira", Vector3(-3.8, y, -9.5), rng.randf_range(-8, 8))
	for y in [0.0, 0.6]:
		item("caixa_madeira", Vector3(-3.8, y, -8.8), rng.randf_range(-8, 8))
	item("carrinho_carga", Vector3(-4.0, 0, -6.4), 30)
	item("paleteira", Vector3(-12.6, 0, -5.4), 90)


func _rack(center: Vector3, length: float) -> void:
	var steel := Color("e65100")
	var board := Color("90a4ae")
	var levels := [0.0, 1.4, 2.8]
	for level in levels:
		decor_item("Prateleira", BOX, Vector3(length, 0.1, 1.0), board, center + Vector3(0, level, 0))
	for x in [-length * 0.5, -length / 6.0, length / 6.0, length * 0.5]:
		for side in [-0.55, 0.55]:
			decor_item("Montante", BOX, Vector3(0.1, 3.2, 0.1), steel, center + Vector3(x, 0, side))
	var slots := int(length / 0.75)
	for level in levels:
		for i in slots:
			var at := center + Vector3(-length * 0.5 + 0.4 + i * 0.75, level + 0.1, 0)
			var roll := rng.randf()
			if roll < 0.45:
				item("caixa_madeira", at)
			elif roll < 0.65:
				item("caixa_papelao", at, 0, ["bfa27a", "e0c99a"])
			elif roll < 0.75:
				item("galao_quimico", at, 90)


func _add_barrels() -> void:
	var red := ["c62828", "8e0000", "eceff1"]
	var blue := ["1565c0", "0d47a1", "eceff1"]
	var yellow := ["f9a825", "f57f17", "212121"]
	for x in [6.5, 7.15, 7.8]:
		for z in [-8.4, -7.75]:
			item("tambor", Vector3(x, 0, z), 0, red)
	for x in [10.0, 10.65, 11.3]:
		for z in [-8.4, -7.75]:
			item("tambor", Vector3(x, 0, z), 0, blue)
	for x in [13.9, 14.55]:
		for z in [-7.5, -6.85]:
			item("tambor", Vector3(x, 0, z), 0, yellow)
	decor_kind("pallet", Vector3(8.5, 0, -6.0))
	item("tambor_deitado", Vector3(8.5, 0.15, -6.0))
	item("tambor_deitado", Vector3(12.0, 0, -6.0), 90)
	for x in [9.0, 9.6]:
		item("galao_quimico", Vector3(x, 0, -9.3))
	item("tambor", Vector3(5.5, 0, -6.4), 0, blue)
	item("extintor", Vector3(14.75, 0, -9.0))


func _add_production_line() -> void:
	# Duas esteiras (x -9..5) com máquinas nas pontas; produtos em cima delas.
	var lines := [
		{"z": -2.5, "machine": ["fbc02d", "455a64", "37474f"], "product": "box"},
		{"z": 2.5, "machine": ["f57c00", "455a64", "37474f"], "product": "can"},
	]
	for line in lines:
		var z: float = line.z
		for i in 7:
			decor_kind("esteira", Vector3(-8 + i * 2.0, 0, z))
		decor_kind("maquina", Vector3(-10.4, 0, z), 90, line.machine)
		decor_kind("maquina", Vector3(6.4, 0, z), -90, line.machine)
		for i in 9:
			if rng.randf() < 0.2:
				continue
			var at := Vector3(-8 + i * 1.5, 0.86, z)
			if line.product == "box":
				prop("Produto", BOX, Vector3(0.4, 0.4, 0.4), CRATE_COLOR, at)
			else:
				prop("Lata", CYLINDER, Vector3(0.3, 0.4, 0.3), Color("b0bec5"), at)


func _add_workshop() -> void:
	var bench := ["6d4c41", "4e342e", "4e342e"]
	for z in [-2.6, -1.4, -0.2]:
		wall_item("bancada", "E", 15, z, 0.0, true, bench)
	item("caixa_ferramentas", Vector3(14.4, 0.9, -2.6), 90)
	item("caixa_ferramentas", Vector3(14.4, 0.9, -0.2), 70)
	item("lata_tinta", Vector3(14.4, 0.9, -1.5), 0, ["b0bec5", "fbc02d"])
	item("lata_tinta", Vector3(14.4, 0.9, -1.1), 0, ["b0bec5", "1976d2"])
	wall_item("armario_ferramentas", "E", 15, -4.2, 0.0)
	wall_item("armario_ferramentas", "E", 15, 1.0, 0.0)
	for at in [Vector3(14.5, 0, 2.2), Vector3(14.5, 0, 2.6), Vector3(14.5, 0, 3.0), Vector3(14.1, 0, 2.4)]:
		item("cilindro_gas", at)
	item("compressor", Vector3(12.5, 0, -3.8), 20)
	item("gerador", Vector3(12.4, 0, 1.4), -15)
	item("cavalete", Vector3(11.0, 0, -1.0), 90)
	item("cavalete", Vector3(11.0, 0, 0.6), 90)
	for at in [Vector3(9.8, 0, 3.7), Vector3(11.1, 0, 3.7)]:
		item("bobina", at, 90)
	item("lixeira_industrial", Vector3(9, 0, -4.2))
	item("extintor", Vector3(14.75, 0, 4.2))
	item("cone", Vector3(8.5, 0, 4.2))


func _add_lockers() -> void:
	# Vestiário junto à parede oeste: armários iguais lado a lado.
	for i in 6:
		wall_item("armario_vestiario", "W", -15, 1.6 + i * 0.55, 0.0)
	item("banco_refeitorio", Vector3(-13.3, 0, 3.0), 90)
	item("capacete", Vector3(-13.3, 0.45, 2.3))
	item("capacete", Vector3(-12.6, 0, 4.6))
	item("capacete", Vector3(-12.2, 0, 1.3), 40)
	item("bebedouro", Vector3(-14.6, 0, 5.4))
	item("lixeira", Vector3(-14.6, 0, 6.2))
	item("extintor", Vector3(-14.75, 0, -1.6))


func _add_docks() -> void:
	for x in [-13.5, -12.1]:
		item("pallet_caixas", Vector3(x, 0, 6.8), 90)
	item("pallet_caixas", Vector3(-13.5, 0, 8.4), 90)
	item("pallet", Vector3(-12.1, 0, 8.4), 90)
	item("pallet", Vector3(-12.1, 0.15, 8.4), 95)
	item("pallet", Vector3(-12.1, 0.3, 8.4), 88)
	item("paleteira", Vector3(-8.0, 0, 7.0), 180)
	item("paleteira", Vector3(-6.6, 0, 7.0), 175)
	for at in [Vector3(-13.6, 0, 10.2), Vector3(-13.0, 0, 10.2), Vector3(-13.3, 0.6, 10.2)]:
		item("caixa_madeira", at)
	_forklift(Vector3(-5, 0, 9.6), 0.0)
	item("cone", Vector3(-6.6, 0, 4.8))
	item("cone", Vector3(-6.0, 0, 4.8))
	item("extintor", Vector3(-1, 0, 10.75))


func _add_center() -> void:
	# Sul do galpão.
	item("pallet_caixas", Vector3(2, 0, 6.5))
	item("bobina", Vector3(-1.5, 0, 6.8), 90)
	item("caixote", Vector3(4.5, 0, 7.0))
	item("caixote", Vector3(4.5, 1.0, 7.0), 8)
	item("caixote", Vector3(5.6, 0, 7.4))
	item("cone", Vector3(3.5, 0, 8.3))
	item("carrinho_mao", Vector3(-2.5, 0, 4.2), 120)
	# Norte do galpão (em volta da porta do almoxarifado).
	item("caixote", Vector3(1.6, 0, -10.2))
	item("caixote", Vector3(2.7, 0, -10.2))
	item("caixote", Vector3(1.6, 1.0, -10.2), 5)
	item("extintor", Vector3(-2.8, 0, -10.75))
	item("pallet", Vector3(4.5, 0, -9.5))
	item("saco_cimento", Vector3(4.5, 0.15, -9.5))
	item("cone", Vector3(-2, 0, -6))
	item("cone", Vector3(-1.4, 0, -6))


func _add_mezzanine() -> void:
	var top := MEZZANINE_HEIGHT
	# Escritório em cima.
	wall_item("mesa_escritorio", "S", 11, 11.0, top)
	item("cadeira_escritorio", Vector3(11.0, top, 9.6))
	for z in [6.2, 6.8, 7.4]:
		wall_item("arquivo_aco", "E", 15, z, top)
	item("impressora", Vector3(12.8, top, 10.5))
	item("bebedouro", Vector3(14.6, top, 9.4))
	item("vaso_planta_alto", Vector3(8, top, 5.6))
	for at in [Vector3(9.4, top, 5.7), Vector3(10.0, top, 5.7), Vector3(9.7, top + 0.4, 5.7)]:
		item("caixa_papelao", at, 0, ["eceff1", "b0bec5"])
	item("lixeira", Vector3(13.6, top, 10.6))
	# Depósito embaixo do mezanino.
	for x in [9.0, 9.6, 10.2, 13.0, 13.6, 14.2]:
		item("caixa_madeira", Vector3(x, 0, 10.5))
	for x in [9.0, 9.6, 13.6]:
		item("caixa_madeira", Vector3(x, 0.6, 10.5))
	for at in [Vector3(12, 0, 6.2), Vector3(12.65, 0, 6.2), Vector3(12, 0, 6.85)]:
		item("tambor", at, 0, ["2e7d32", "1b5e20", "eceff1"])
	item("lata_tinta", Vector3(8.2, 0, 10.5), 0, ["b0bec5", "1976d2"])
	item("lata_tinta", Vector3(8.55, 0, 10.5), 0, ["b0bec5", "1976d2"])
	item("cilindro_gas", Vector3(14.6, 0, 6.0))
	item("cilindro_gas", Vector3(14.6, 0, 6.4))


# --- Anexos ---------------------------------------------------------------------

func _add_canteen() -> void:
	var y := 0.0
	for z in [-9.0, -6.2, -3.4]:
		item("mesa_refeitorio", Vector3(-21, y, z))
		item("banco_refeitorio", Vector3(-21, y, z - 0.75))
		item("banco_refeitorio", Vector3(-21, y, z + 0.75), 180)
	for z in [-10.0, -8.9, -7.8]:
		wall_item("maquina_venda", "W", -27, z, y, false, ["c62828" if z < -9 else "1565c0", "b3e5fc", "212121"])
	wall_item("maquina_cafe", "W", -27, -4.0, y)
	wall_item("bebedouro", "W", -27, -2.6, y)
	wall_item("bancada", "E", -15, -9.5, y, true)
	wall_item("bancada", "E", -15, -8.3, y, true)
	item("micro_ondas", Vector3(-15.55, y + 0.9, -9.5), -90)
	item("micro_ondas", Vector3(-15.55, y + 0.9, -8.3), -90)
	wall_item("geladeira", "E", -15, -7.0, y)
	item("lixeira", Vector3(-15.5, y, -2.0))
	item("lixeira", Vector3(-17.0, y, -10.6))
	item("vaso_planta_alto", Vector3(-26.5, y, -1.9))


func _add_admin_office() -> void:
	var y := 0.0
	# Seis baias com divisórias baixas.
	var partition := Color("90a4ae")
	for z in [4.8, 8.2]:
		wall_box(Vector3(-21, 0.65, z), Vector3(9.0, 1.3, 0.08), partition)
	for x in [-24.0, -18.0]:
		wall_box(Vector3(x, 0.65, 6.5), Vector3(0.08, 1.3, 7.0), partition)
	for x in [-25.5, -21.0, -16.5]:
		item("mesa_escritorio", Vector3(x, y, 4.2), 180)
		item("cadeira_escritorio", Vector3(x, y, 3.3), 0)
		item("mesa_escritorio", Vector3(x, y, 8.8))
		item("cadeira_escritorio", Vector3(x, y, 9.7), 180)
	for x in [-26.0, -25.4, -24.8]:
		wall_item("arquivo_aco", "S", 11, x, y)
	item("impressora", Vector3(-15.6, y, 6.5), -90)
	wall_item("bebedouro", "E", -15, 10.3, y)
	for at in [Vector3(-26.5, y, 2.0), Vector3(-15.6, y, 2.0), Vector3(-21, y, 10.5)]:
		item("vaso_planta_alto", at)
	item("lixeira", Vector3(-19.5, y, 6.5))
	item("caixa_papelao", Vector3(-23.0, y, 6.5), 0, ["eceff1", "b0bec5"])


func _add_machine_room() -> void:
	var y := BASEMENT
	# Sala norte: tanques.
	for at in [Vector3(-25.2, y, -9.2), Vector3(-22.6, y, -9.2), Vector3(-25.2, y, -6.4)]:
		decor_kind("tanque_industrial", at)
	item("gerador", Vector3(-18, y, -9.5))
	item("gerador", Vector3(-17, y, -9.5), 10)
	item("compressor", Vector3(-19.5, y, -6.0), 90)
	item("tambor", Vector3(-16, y, -6.0))
	item("tambor", Vector3(-16, y, -6.65))
	# Sala do meio: chegada da escada, ferramentas.
	wall_item("prateleira_metal", "W", -27, 2.6, y, true)
	wall_item("armario_ferramentas", "S", 4, -19.5, y)
	item("caixa_ferramentas", Vector3(-25.0, y, -2.8))
	item("cilindro_gas", Vector3(-15.6, y, -3.3))
	item("cilindro_gas", Vector3(-15.6, y, -2.9))
	item("cilindro_gas", Vector3(-16.0, y, -3.1))
	item("tambor_deitado", Vector3(-17.5, y, 2.6))
	# Sala sul: gerador grande e tubulação.
	decor_item("GeradorGrande", BOX, Vector3(2.4, 2.0, 1.6), Color("455a64"), Vector3(-24.5, y, 8.4))
	decor_item("GeradorPainel", BOX, Vector3(0.8, 0.5, 0.05), Color("e65100"), Vector3(-24.5, y + 1.1, 7.58))
	for at in [Vector3(-20, y, 9.5), Vector3(-19, y, 9.5), Vector3(-16.3, y, 6.0)]:
		item("gerador", at, rng.randf_range(-20, 20))
	item("compressor", Vector3(-18.5, y, 6.0), 70)
	for at in [Vector3(-16, y, 10.3), Vector3(-16.6, y, 10.3), Vector3(-16.3, y, 9.7)]:
		item("tambor", at, 0, ["c62828", "8e0000", "eceff1"])
	var pipes := add_group("Tubos")
	for z in [-10.4, 10.4]:
		var pipe := CSGCylinder3D.new()
		pipe.name = "Tubo%d" % (pipes.get_child_count() + 1)
		pipe.radius = 0.15
		pipe.height = 12
		pipe.rotation_degrees.z = 90
		pipe.position = Vector3(-21, -0.7, z)
		pipe.material = PropBuilder.get_material(Color("e65100"))
		pipes.add_child(pipe)


func _add_warehouse() -> void:
	# Almoxarifado: corredores de prateleiras com caixas pequenas.
	var y := 0.0
	for z in [-17.8, -15.0]:
		for x in [-13.5, -12.4, -9.5, -8.4, -5.5, -4.4]:
			decor_kind("prateleira_metal", Vector3(x, y, z), 0.0 if z < -16 else 180.0)
			decor_kind("prateleira_metal", Vector3(x, y, z + 0.5), 180.0 if z < -16 else 0.0)
	for at in [Vector3(-11.0, y, -16.4), Vector3(-7.0, y, -16.4), Vector3(-3.0, y, -16.4), Vector3(-14.4, y, -12.0),
			Vector3(-10.6, y, -12.0), Vector3(-3.4, y, -12.0), Vector3(1.6, y, -18.4), Vector3(2.2, y, -18.4),
			Vector3(1.9, y + 0.4, -18.4)]:
		item("caixa_papelao", at, rng.randf_range(-10, 10))
	for at in [Vector3(-6.9, y, -12.0), Vector3(-6.5, y, -12.0), Vector3(1.0, y, -13.0), Vector3(2.4, y, -15.0)]:
		item("galao_quimico", at, rng.randf_range(0, 90))
	item("pallet", Vector3(0.8, y, -15.6), 90)
	item("saco_cimento", Vector3(0.8, y + 0.15, -16.0), 90)
	item("saco_cimento", Vector3(0.8, y + 0.15, -15.2), 90)
	item("carrinho_carga", Vector3(-1.0, y, -17.8), 200)
	item("paleteira", Vector3(-1.2, y, -13.2), 80)


func _add_cold_room() -> void:
	var y := 0.0
	var white := ["eceff1", "b0bec5", "fafafa"]
	for x in [4.2, 5.6]:
		item("pallet_caixas", Vector3(x, y, -18.2), 0, white)
	item("pallet_caixas", Vector3(4.2, y, -16.8), 0, white)
	for x in [13.8, 12.4]:
		item("pallet_caixas", Vector3(x, y, -18.2), 0, white)
	wall_item("freezer", "E", 15, -14.0, y)
	wall_item("freezer", "E", 15, -12.6, y)
	for at in [Vector3(8.0, y, -18.4), Vector3(8.7, y, -18.4), Vector3(8.35, y + 0.44, -18.4), Vector3(10.2, y, -18.4),
			Vector3(6.5, y, -12.0), Vector3(7.2, y, -12.0), Vector3(12.5, y, -12.0)]:
		item("caixa_isopor", at)
	item("carrinho_carga", Vector3(10.5, y, -15.2), -20)
	item("paleteira", Vector3(6.0, y, -14.8), 100)
	item("tambor", Vector3(4.0, y, -12.2), 0, ["b0bec5", "78909c", "eceff1"])


func _add_yard() -> void:
	var y := 0.0
	# Contêineres: uma fileira encostada no anexo e um bloco empilhado.
	var colors := [Color("c62828"), Color("1565c0"), Color("2e7d32"), Color("ef6c00"), Color("6a1b9a"), Color("00838f")]
	_container(Vector3(-23, y, 14.0), 0.0, colors[0])
	_container(Vector3(-23, y, 18.0), 180.0, colors[1])
	_container(Vector3(-23, y, 22.0), 0.0, colors[2])
	_container(Vector3(-23, y, 26.0), 180.0, colors[3])
	_container(Vector3(-15.5, y, 16.5), 90.0, colors[4])
	_container(Vector3(-15.5, y, 25.0), -90.0, colors[5])
	for at in [Vector3(-23, 2.6, 14.0), Vector3(-23, 2.6, 22.0), Vector3(-15.5, 2.6, 16.5)]:
		var size := Vector3(6, 2.6, 2.4) if at.x < -20 else Vector3(2.4, 2.6, 6)
		wall_box(at + Vector3(0, 1.3, 0), size, colors[(int(at.z) + 1) % colors.size()].darkened(0.15))
	# Caminhão-baú encostado na doca, aberto para o galpão.
	_truck(Vector3(-10, y, 16.2))
	# Bobinas, pallets e entulho.
	for at in [Vector3(-2, y, 13.5), Vector3(-0.6, y, 13.5), Vector3(-1.3, y, 14.9), Vector3(4.0, y, 25.0),
			Vector3(5.4, y, 25.0)]:
		item("bobina", at, 90)
	for at in [Vector3(2.0, y, 20.0), Vector3(3.4, y, 20.0), Vector3(2.0, y, 21.6)]:
		item("pallet_caixas", at, rng.randf_range(-5, 5))
	for i in 4:
		item("pallet", Vector3(-4.0, y + i * 0.15, 22.0), rng.randf_range(-6, 6))
	for at in [Vector3(12.5, y, 13.0), Vector3(13.4, y, 13.0), Vector3(-27.6, y, 29.0), Vector3(-6.5, y, 28.8)]:
		item("lixeira_industrial", at, rng.randf_range(-10, 10))
	decor_item("Cacamba", BOX, Vector3(3.6, 1.4, 1.8), Color("ef6c00"), Vector3(8.0, y, 28.8))
	decor_item("Cacamba", BOX, Vector3(3.6, 1.4, 1.8), Color("ef6c00"), Vector3(-24.0, y, -17.0))
	for at in [Vector3(-6, y, 12.6), Vector3(-5.2, y, 12.6), Vector3(0.8, y, 17.5), Vector3(6.5, y, 16.0),
			Vector3(-12.5, y, 23.5), Vector3(14.5, y, 21.0)]:
		item("cone", at)
	item("cavalete", Vector3(7.5, y, 19.0), 30)
	item("cavalete", Vector3(-3.0, y, 26.5), -15)
	for at in [Vector3(-11.0, y, 25.5), Vector3(-10.4, y, 25.5), Vector3(-10.7, y, 26.1)]:
		item("tambor", at, 0, ["c62828", "8e0000", "eceff1"])
	item("tambor_deitado", Vector3(0.0, y, 27.5), 30)
	item("carrinho_mao", Vector3(6.0, y, 13.0), 200)
	_forklift(Vector3(10.5, y, 17.0), 90.0)
	# Guarita no portão sul (portão fechado: o terreno é cercado).
	var booth := Color("eceff1")
	wall_x(25.5, 11.5, 15.5, [door(13.5, DOOR, 2.2)], booth, 2.6)
	wall_x(29.5, 11.5, 15.5, [[13.5, 2.0, 1.0, 2.0]], booth, 2.6)
	wall_z(11.5, 25.5, 29.5, [[27.5, 1.6, 1.0, 2.0]], booth, 2.6)
	wall_z(15.5, 25.5, 29.5, [], booth, 2.6)
	wall_box(Vector3(13.5, 2.7, 27.5), Vector3(4.6, 0.2, 4.6), Color("9e9e9e"))
	wall_item("mesa_escritorio", "S", 29.5, 13.5, y)
	item("cadeira_escritorio", Vector3(13.5, y, 27.8))
	item("bebedouro", Vector3(12.0, y, 26.0))
	item("extintor", Vector3(15.1, y, 26.0))
	# Sucata atrás do anexo oeste.
	for at in [Vector3(-27.5, y, -12.5), Vector3(-26.8, y, -12.5), Vector3(-20.0, y, -12.8), Vector3(-18.5, y, -18.6)]:
		item("tambor", at, 0, ["6d4c41", "4e342e", "8d6e63"])
	for i in 3:
		item("pallet", Vector3(-17.0, y + i * 0.15, -15.0), rng.randf_range(-10, 10))
	item("pneu", Vector3(-21.5, y, -14.5))
	item("pneu", Vector3(-21.5, y + 0.21, -14.5))
	item("bobina", Vector3(-26.5, y, -16.0), 0)


func _add_lights() -> void:
	for at in [Vector3(-9, 6, -8), Vector3(10, 6, -8), Vector3(-7.5, 6, 0), Vector3(0, 6, 0),
			Vector3(7.5, 6, 0), Vector3(-9, 6, 8), Vector3(2, 6, 8)]:
		add_light(lights, at, 11.0, 0.9)
	add_light(lights, Vector3(11, 2.3, 8), 6.0, 0.5)
	for at in [Vector3(-21, 2.6, -6), Vector3(-21, 2.6, 0), Vector3(-21, 2.6, 6)]:
		add_light(lights, at, 8.0, 0.8)
	for at in [Vector3(-21, -0.8, -7.5), Vector3(-21, -0.8, 0), Vector3(-21, -0.8, 7.5)]:
		add_light(lights, at, 7.0, 0.6, Color("ffb74d"))
	for at in [Vector3(-10, 3.0, -15), Vector3(-3, 3.0, -15)]:
		add_light(lights, at, 8.0, 0.7)
	for at in [Vector3(6, 3.0, -15), Vector3(12, 3.0, -15)]:
		add_light(lights, at, 8.0, 0.9, Color("80d8ff"))
	add_light(lights, Vector3(13.5, 2.3, 27.5), 4.0, 0.6)


# --- Peças compostas ----------------------------------------------------------------

## Contêiner oco com uma das pontas aberta. Com yaw 0 o comprimento fica em X e a
## ponta aberta aponta para +X.
func _container(base: Vector3, yaw: float, color: Color, size := Vector3(6, 2.6, 2.4)) -> void:
	var combiner := CSGCombiner3D.new()
	combiner.name = "Conteiner%d" % (decor.get_child_count() + 1)
	combiner.use_collision = true
	combiner.position = base + Vector3(0, size.y * 0.5, 0)
	combiner.rotation_degrees.y = yaw
	var outer := CSGBox3D.new()
	outer.name = "Casco"
	outer.size = size
	outer.material = PropBuilder.get_material(color)
	combiner.add_child(outer)
	var wall := 0.1
	var inner := CSGBox3D.new()
	inner.name = "Interior"
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	inner.size = size - Vector3(wall, wall * 2.0, wall * 2.0)
	inner.position = Vector3(wall, 0, 0)
	inner.material = PropBuilder.get_material(color.darkened(0.4))
	combiner.add_child(inner)
	decor.add_child(combiner)
	var extent := Vector3(size.x, size.y, size.z) if absf(sin(deg_to_rad(yaw))) < 0.5 else Vector3(size.z, size.y, size.x)
	_bounds.append({"name": combiner.name, "aabb": AABB(base - Vector3(extent.x, 0, extent.z) * 0.5, extent), "wall": true})


## Caminhão-baú com a porta traseira (norte) aberta; dá para entrar pela rampa.
func _truck(rear_center: Vector3) -> void:
	var floor_y := 0.4
	var box := Vector3(2.5, 2.7, 8.0)
	_container(rear_center + Vector3(0, floor_y - 0.1, 0), 90.0, Color("eceff1"), Vector3(box.z, box.y, box.x))
	decor_item("Chassi", BOX, Vector3(2.2, floor_y - 0.1, box.z), Color("263238"), rear_center)
	stairs(rear_center + Vector3(0, 0, -box.z * 0.5 - 1.2), rear_center + Vector3(0, floor_y, -box.z * 0.5 + 0.1), 2.2,
		Color("616161"))
	var cab := rear_center + Vector3(0, 0, box.z * 0.5 + 1.3)
	decor_item("Cabine", BOX, Vector3(2.5, 2.4, 2.2), Color("1565c0"), cab + Vector3(0, 0.4, 0))
	decor_item("Parabrisa", BOX, Vector3(2.2, 0.8, 0.05), Color("263238"), cab + Vector3(0, 1.7, 1.1))


func _forklift(at: Vector3, yaw: float) -> void:
	var yellow := Color("fbc02d")
	var dark := Color("424242")
	var basis := Basis(Vector3.UP, deg_to_rad(yaw))
	decor_item("Empilhadeira", BOX, Vector3(1.2, 1.1, 1.8), yellow, at, yaw)
	decor_item("EmpilhadeiraMastro", BOX, Vector3(1.0, 2.2, 0.15), dark, at + basis * Vector3(0, 0, -1.0), yaw)
	for x in [-0.35, 0.35]:
		decor_item("EmpilhadeiraGarfo", BOX, Vector3(0.15, 0.06, 1.0), dark, at + basis * Vector3(x, 0.1, -1.6), yaw)
	for offset in [Vector3(-0.55, 1.1, -0.35), Vector3(0.55, 1.1, -0.35), Vector3(-0.55, 1.1, 0.75), Vector3(0.55, 1.1, 0.75)]:
		decor_item("EmpilhadeiraHaste", CYLINDER, Vector3(0.08, 0.9, 0.08), dark, at + basis * offset)
	decor_item("EmpilhadeiraTeto", BOX, Vector3(1.2, 0.08, 1.2), dark, at + basis * Vector3(0, 2.0, 0.2), yaw)
