extends "res://tools/map_builder.gd"
## Gera res://scenes/maps/house.tscn (mapa "Casa"): um sobrado com porão, sótão,
## garagem e quintal.
## Uso: godot --headless --path . -s res://tools/build_house.gd
##
## Planta (x = leste, z = sul; a frente da casa fica em z = 7):
##   Porão  (y = -3,2): x -12..4, z -7..1. Adega a oeste, sinuca e depósito a leste.
##   Térreo (y = 0):    salas de TV e de jantar a oeste; hall com a escada, corredor,
##                      banheiro com chuveiro e despensa no meio; cozinha, escritório
##                      e lavanderia a leste. Garagem em x 12..19.
##   Andar  (y = 3,2):  quarto do casal, banheiro com banheira e quarto de criança ao
##                      norte; quarto do bebê, sala íntima e quarto de hóspedes ao sul.
##   Sótão  (y = 6,4):  embaixo do telhado de duas águas (cumeeira em z = 0).

const GROUND := 0.0
const UPPER := 3.2
const ATTIC := 6.4
const BASEMENT := -3.2
const ROOM_HEIGHT := 3.0
## Cumeeira do telhado e beiral (o telhado desce até o piso do sótão em z = ±EAVE_Z).
const RIDGE_Y := 9.2
const EAVE_Z := 7.4

const OUTER := Color("e8dcc8")
const INNER := Color("f2ece0")
const BASEMENT_WALL := Color("9e9e9e")
const ATTIC_WOOD := Color("a1887f")
const ROOF := Color("8d3a2a")
const FENCE := Color("f5f5f5")
const STAIRS := Color("8d6e63")
const CEILING := Color("fafafa")

## Vão de escada no piso do térreo (porão) e do sótão.
const BASEMENT_STAIR_HOLE := Rect2(-2.3, -0.5, 4.9, 1.1)
const MAIN_STAIR_HOLE := Rect2(1.8, 2.1, 1.2, 4.6)
const ATTIC_STAIR_HOLE := Rect2(-5.6, 1.0, 4.6, 1.0)

var lights: Node3D


func _init() -> void:
	out_path = "res://scenes/maps/house.tscn"
	map_name = "Casa"
	root_name = "House"
	wall_height = ROOM_HEIGHT


func _build() -> void:
	seed(20261025)
	var env := add_environment(Color("4f7fbf"), Color("b9d3ee"))
	env.ambient_light_energy = 0.75
	# Chão do céu claro e neutro: aparece pelas janelas do andar de cima e
	# ilumina os forros (que olham para baixo) sem tingir de verde.
	var sky_material := env.sky.sky_material as ProceduralSkyMaterial
	sky_material.ground_horizon_color = Color("b4bcaa")
	sky_material.ground_bottom_color = Color("9a9a90")
	_add_floors()
	lights = add_group("Lights")
	_add_ground_walls()
	_add_upper_walls()
	_add_basement_walls()
	_add_roof_and_attic()
	_add_garage_and_fence()
	_add_stairs()
	add_content_groups()
	_furnish_living_room()
	_furnish_dining_room()
	_furnish_hall_and_corridor()
	_furnish_bathroom_and_pantry()
	_furnish_kitchen()
	_furnish_office_and_laundry()
	_furnish_garage()
	_furnish_yards()
	_furnish_master_bedroom()
	_furnish_tub_bathroom()
	_furnish_kids_room()
	_furnish_baby_room()
	_furnish_family_room_and_guest_room()
	_furnish_attic()
	_furnish_basement()
	_add_lights()
	add_markers([
		Vector3(-2, 0.1, 4.5), Vector3(-6.3, 0.1, 3.0), Vector3(-10.8, 0.1, -1.5), Vector3(9.5, 0.1, -4.0),
		Vector3(-3.2, 0.1, 1.2), Vector3(5.0, 0.1, 3.5), Vector3(10.8, 0.1, 2.0), Vector3(13.4, 0.1, 0.4),
		Vector3(6, UPPER + 0.1, 1.0), Vector3(-6.5, UPPER + 0.1, -3.0), Vector3(6.5, UPPER + 0.1, -5.0),
		Vector3(-9.0, UPPER + 0.1, 4.6), Vector3(-1.0, UPPER + 0.1, 3.5), Vector3(6.0, UPPER + 0.1, 4.0),
		Vector3(2, ATTIC + 0.1, 0), Vector3(0.5, BASEMENT + 0.1, -3.5), Vector3(-4, 0.1, -11),
		Vector3(12, 0.1, -12), Vector3(6, 0.1, 9.5),
	], Vector3(30, 0.1, 0), Vector3(-1, 0.1, 9.5))


# --- Pisos e lajes -------------------------------------------------------------

func _add_floors() -> void:
	var floors := add_group("Floors")
	# Gramado do terreno, com o buraco do porão.
	add_slab(floors, "Grama", Rect2(-60, -60, 120, 120), -0.02, Color("6a994e"), [Rect2(-12, -7, 16, 8)])
	add_floor(floors, "Calcada", Rect2(-2, 7, 2, 4), Color("bcaaa4"), 0.0)
	add_floor(floors, "Entrada", Rect2(12.5, 7, 6, 4), Color("9e9e9e"), 0.0)
	add_floor(floors, "Deck", Rect2(-4, -10, 8, 3), Color("a1887f"), 0.0)

	# Térreo (cada cômodo com a sua cor; o corredor tem o vão da escada do porão).
	add_floor(floors, "PisoSalaTV", Rect2(-12, 0, 8, 7), Color("8d6e4f"))
	add_floor(floors, "PisoJantar", Rect2(-12, -7, 8, 7), Color("a1887f"))
	add_floor(floors, "PisoHall", Rect2(-4, 2, 7, 5), Color("bcaaa4"))
	add_slab(floors, "PisoCorredor", Rect2(-4, -3, 7, 5), GROUND, Color("bcaaa4"), [BASEMENT_STAIR_HOLE])
	add_floor(floors, "PisoBanheiro", Rect2(-4, -7, 4, 4), Color("b2ebf2"))
	add_floor(floors, "PisoDespensa", Rect2(0, -7, 3, 4), Color("d7ccc8"))
	add_floor(floors, "PisoCozinha", Rect2(3, -7, 9, 7), Color("cfd8dc"))
	add_floor(floors, "PisoEscritorio", Rect2(3, 0, 5, 7), Color("d7ccc8"))
	add_floor(floors, "PisoLavanderia", Rect2(8, 0, 4, 7), Color("b0bec5"))
	add_floor(floors, "PisoGaragem", Rect2(12, -1, 7, 8), Color("9e9e9e"))

	# Andar de cima: laje com o vão da escada principal.
	add_floor(floors, "PisoCasal", Rect2(-12, -7, 9, 7), Color("9fa8da"), UPPER)
	add_floor(floors, "PisoBanheira", Rect2(-3, -7, 6, 7), Color("b2ebf2"), UPPER)
	add_floor(floors, "PisoCrianca", Rect2(3, -7, 9, 7), Color("c5e1a5"), UPPER)
	add_floor(floors, "PisoCorredorCima", Rect2(-12, 0, 24, 2), Color("a1887f"), UPPER)
	add_floor(floors, "PisoBebe", Rect2(-12, 2, 8, 5), Color("f8bbd0"), UPPER)
	add_slab(floors, "PisoSalaIntima", Rect2(-4, 2, 7, 5), UPPER, Color("bcaaa4"), [MAIN_STAIR_HOLE])
	add_floor(floors, "PisoHospedes", Rect2(3, 2, 9, 5), Color("d7ccc8"), UPPER)
	add_floor(floors, "TetoGaragem", Rect2(12, -1, 7, 8), Color("8d6e63"), UPPER)

	# Sótão e porão.
	add_slab(floors, "PisoSotao", Rect2(-12, -7, 24, 14), ATTIC, Color("a1887f"), [ATTIC_STAIR_HOLE])
	add_floor(floors, "PisoPorao", Rect2(-12, -7, 16, 8), Color("78909c"), BASEMENT)

	add_seeker_cage(floors, Vector3(30, 0, 0))

	var ceilings := add_group("Ceilings")
	var house := Rect2(-12, -7, 24, 14)
	add_ceiling(ceilings, "Forro", house, UPPER - 0.2, CEILING, [MAIN_STAIR_HOLE])
	add_ceiling(ceilings, "ForroCima", house, ATTIC - 0.2, CEILING, [ATTIC_STAIR_HOLE])
	add_ceiling(ceilings, "ForroPorao", Rect2(-12, -7, 16, 8), GROUND - 0.2, Color("bdbdbd"), [BASEMENT_STAIR_HOLE])
	add_ceiling(ceilings, "ForroGaragem", Rect2(12, -1, 7, 8), 3.0, CEILING)


# --- Paredes -------------------------------------------------------------------
# Vãos: [centro, largura] até o teto, ou [centro, largura, peitoril, topo].

func _window(center: float, width := 1.8, sill := 1.0) -> Array:
	return [center, width, sill, 2.3]


func _add_ground_walls() -> void:
	var h := UPPER
	# Fachadas.
	wall_x(-7, -12, 12, [_window(-10.4, 1.4), door(-8, MAIN_DOOR), [-2, 0.6, 1.6, 2.2], _window(5.5, 1.6),
		door(10.0, MAIN_DOOR)], OUTER, h)
	wall_x(7, -12, 12, [_window(-9.5, 2.0, 0.9), _window(-6, 2.0, 0.9), door(-1, MAIN_DOOR, 2.4),
		_window(5.5, 2.0, 0.9), [10, 1.0, 1.4, 2.2]], OUTER, h)
	wall_z(-12, -7, 7, [_window(-3.5, 2.0, 0.9), _window(5.8, 1.6, 0.9)], OUTER, h)
	wall_z(12, -7, 7, [_window(-3.5, 1.6), door(3.5)], OUTER, h)
	# Divisões internas.
	wall_z(-4, -7, 7, [door(-1), door(4.5, MAIN_DOOR, 2.4)], INNER)
	wall_x(0, -12, -4, [[-8, 3.0, 0.0, 2.6]], INNER)
	wall_x(2, -4, 3, [[-1, 3.0, 0.0, 2.6]], INNER)
	wall_x(-3, -4, 3, [door(-2), door(1.5)], INNER)
	wall_z(0, -7, -3, [], INNER)
	wall_z(3, -7, 7, [door(-1.5, MAIN_DOOR, 2.4), door(1.0)], INNER)
	wall_x(0, 3, 12, [door(10)], INNER)
	wall_z(8, 0, 7, [], INNER)
	# Guarda-corpo do vão da escada do porão (a entrada fica a oeste).
	var rail := BASEMENT_STAIR_HOLE
	wall_x(rail.position.y, rail.position.x, rail.end.x, [], INNER, 1.0)
	wall_x(rail.end.y, rail.position.x, rail.end.x, [], INNER, 1.0)
	wall_z(rail.end.x, rail.position.y, rail.end.y, [], INNER, 1.0)


func _add_upper_walls() -> void:
	var base := UPPER
	wall_x(-7, -12, 12, [_window(-9, 2.0), [0, 0.8, 1.6, 2.2], _window(7.5, 2.0)], OUTER, 3.2, base)
	wall_x(7, -12, 12, [_window(-8, 2.0), _window(-1, 2.0), _window(7.5, 2.0)], OUTER, 3.2, base)
	wall_z(-12, -7, 7, [_window(-3.5, 2.0), _window(4.5, 1.6)], OUTER, 3.2, base)
	wall_z(12, -7, 7, [_window(-3.5, 2.0), _window(4.5, 1.6)], OUTER, 3.2, base)
	wall_x(0, -12, 12, [door(-5), door(0), door(5)], INNER, -1.0, base)
	wall_x(2, -12, 12, [door(-7), [0.5, 2.2, 0.0, 2.6], [2.4, 1.0]], INNER, -1.0, base)
	wall_z(-3, -7, 0, [], INNER, -1.0, base)
	wall_z(3, -7, 0, [], INNER, -1.0, base)
	wall_z(-4, 2, 7, [], INNER, -1.0, base)
	wall_z(MAIN_STAIR_HOLE.position.x, 2, 7, [], INNER, -1.0, base)
	wall_z(3, 2, 7, [], INNER, -1.0, base)


func _add_basement_walls() -> void:
	var base := BASEMENT
	wall_x(-7, -12, 4, [], BASEMENT_WALL, -1.0, base)
	wall_x(1, -12, 4, [], BASEMENT_WALL, -1.0, base)
	wall_z(-12, -7, 1, [], BASEMENT_WALL, -1.0, base)
	wall_z(4, -7, 1, [], BASEMENT_WALL, -1.0, base)
	# Adega a oeste.
	wall_z(-7, -7, 1, [door(-3)], BASEMENT_WALL, -1.0, base)


func _add_roof_and_attic() -> void:
	var base := ATTIC
	var rise := RIDGE_Y - ATTIC
	# Oitões (paredes triangulares nas pontas do sótão).
	for x in [-12.0, 12.0]:
		var gable := CSGMesh3D.new()
		gable.name = "Oitao%d" % walls.get_child_count()
		var prism := PrismMesh.new()
		prism.size = Vector3(EAVE_Z * 2.0, rise, WALL_THICKNESS)
		gable.mesh = prism
		gable.material = PropBuilder.get_material(OUTER)
		gable.position = Vector3(x, base + rise * 0.5, 0)
		gable.rotation_degrees.y = 90
		walls.add_child(gable)
	# Duas águas, do beiral à cumeeira, com um pouco de beiral para fora.
	var slope := atan2(rise, EAVE_Z)
	var overhang := 0.6
	var length := Vector2(EAVE_Z, rise).length() + overhang
	for side in [-1.0, 1.0]:
		var dir := Vector3(0, -sin(slope), cos(slope) * side)
		var normal := Vector3(0, cos(slope), sin(slope) * side)
		var center := Vector3(0, RIDGE_Y, 0) + dir * (length * 0.5) + normal * 0.1
		wall_box(center, Vector3(25.2, 0.2, length), ROOF, Vector3(rad_to_deg(slope) * side, 0, 0))
		# Forro de madeira por dentro do telhado (só visual).
		var lining := CSGBox3D.new()
		lining.name = "ForroTelhado%d" % (side + 1)
		lining.size = Vector3(24.0, 0.02, length - overhang)
		lining.position = Vector3(0, RIDGE_Y, 0) + dir * ((length - overhang) * 0.5) - normal * 0.015
		lining.rotation_degrees.x = rad_to_deg(slope) * side
		lining.material = PropBuilder.get_material(ATTIC_WOOD)
		map_root.get_node("Ceilings").add_child(lining)
	# Muretas onde o telhado fica baixo, e guarda-corpo do vão da escada.
	wall_x(-5, -12, 12, [], ATTIC_WOOD, 0.9, base)
	wall_x(5, -12, 12, [], ATTIC_WOOD, 0.9, base)
	# O guarda-corpo fica por fora do vão, para não estreitar a passagem.
	var hole := ATTIC_STAIR_HOLE
	var t := WALL_THICKNESS * 0.5
	wall_x(hole.position.y - t, hole.position.x, hole.end.x + t, [], ATTIC_WOOD, 1.0, base)
	wall_x(hole.end.y + t, hole.position.x, hole.end.x + t, [], ATTIC_WOOD, 1.0, base)
	wall_z(hole.end.x + t, hole.position.y - t, hole.end.y + t, [], ATTIC_WOOD, 1.0, base)


func _add_garage_and_fence() -> void:
	# Garagem: portão aberto para a frente, porta lateral para o quintal.
	wall_x(-1, 12, 19, [door(15.5)], OUTER)
	wall_z(19, -1, 7, [], OUTER)
	wall_x(7, 12, 19, [[15.5, 5.6, 0.0, 2.7]], OUTER)
	wall_box(Vector3(15.5, 3.1, 3), Vector3(7.2, 0.2, 8.2), ROOF)
	# Cerca em volta do terreno (alta demais para pular).
	wall_x(-17, -14, 21, [], FENCE, 1.5)
	wall_x(11, -14, 21, [], FENCE, 1.5)
	wall_z(-14, -17, 11, [], FENCE, 1.5)
	wall_z(21, -17, 11, [], FENCE, 1.5)


func _add_stairs() -> void:
	# Hall -> andar de cima, subindo para o norte junto à parede leste do hall.
	# O pé fica 0,9 m antes da parede externa, para dar para chegar pela lateral (oeste).
	stairs(Vector3(2.4, GROUND, 6.0), Vector3(2.4, UPPER, MAIN_STAIR_HOLE.position.y), 1.1, STAIRS)
	# Corredor -> porão: entra pelo lado oeste e desce para o leste.
	var hole := BASEMENT_STAIR_HOLE
	stairs(Vector3(hole.end.x, BASEMENT, hole.get_center().y), Vector3(hole.position.x, GROUND, hole.get_center().y),
		hole.size.y, STAIRS)
	# Corredor de cima -> sótão: estreita, subindo para o oeste.
	var attic := ATTIC_STAIR_HOLE
	stairs(Vector3(attic.end.x, UPPER, attic.get_center().y), Vector3(attic.position.x, ATTIC, attic.get_center().y),
		attic.size.y, STAIRS)


# --- Móveis --------------------------------------------------------------------

func _furnish_living_room() -> void:
	var y := GROUND
	wall_item("rack_tv", "W", -12, 3.5, y, true)
	decor_kind("sofa3", Vector3(-8.0, y, 3.5), -90)
	item("mesa_centro", Vector3(-9.6, y, 3.5), 90)
	wall_item("sofa2", "E", -4, 6.1, y)
	wall_item("estante", "W", -12, 0.9, y)
	item("poltrona", Vector3(-10.6, y, 6.0), 135)
	item("poltrona", Vector3(-6.0, y, 1.1), -45, ["5c6bc0", "7986cb"])
	for z in [1.9, 5.1]:
		item("mesa_lateral", Vector3(-8.0, y, z))
		item("abajur", Vector3(-8.0, y + 0.54, z))
	item("luminaria", Vector3(-11.5, y, 6.5))
	item("pufe", Vector3(-6.0, y, 6.3))
	item("pufe", Vector3(-5.6, y, 2.6), 0, ["ffb300", "ffca28"])
	item("vaso_planta_alto", Vector3(-5.0, y, 0.6))
	prop("Bola", SPHERE, Vector3(0.3, 0.3, 0.3), Color("e53935"), Vector3(-6.6, y, 4.2))


func _furnish_dining_room() -> void:
	var y := GROUND
	table_with_chairs("mesa_jantar", Vector3(-8, y, -3.5), "cadeira",
		[["N", -0.55], ["N", 0.55], ["S", -0.55], ["S", 0.55], ["W", 0.0], ["E", 0.0]])
	wall_item("buffet", "N", -7, -10.4, y, true)
	wall_item("cristaleira", "W", -12, -5.5, y)
	wall_item("aparador", "E", -4, -5.5, y)
	item("abajur", Vector3(-4.32, y + 0.83, -5.0))
	wall_item("cadeira", "E", -4, -3.0, y)
	wall_item("cadeira", "E", -4, -2.4, y)
	item("vaso_planta_alto", Vector3(-11.5, y, -0.6))
	item("vaso_planta_alto", Vector3(-4.6, y, -6.5))


func _furnish_hall_and_corridor() -> void:
	var y := GROUND
	wall_item("sapateira", "S", 7, -3.0, y)
	item("cabideiro", Vector3(-3.6, y, 5.9))
	wall_item("aparador", "W", -4, 2.9, y)
	item("abajur", Vector3(-3.68, y + 0.83, 2.5))
	item("vaso_planta_alto", Vector3(-2.1, y, 6.5))
	item("mala", Vector3(0.9, y, 2.6), 20)
	# Corredor.
	wall_item("estante_baixa", "N", -3, -0.4, y)
	item("vaso_planta", Vector3(-3.6, y, -2.6))
	item("lixeira", Vector3(2.7, y, -2.7))
	item("cesto_roupa", Vector3(1.2, y, 1.6))


func _furnish_bathroom_and_pantry() -> void:
	var y := GROUND
	# Box do chuveiro (vidro) no canto noroeste.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.95, 1.0, 0.3)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decor_item("PisoBox", BOX, Vector3(1.2, 0.05, 1.2), Color("eceff1"), Vector3(-3.3, y, -6.3))
	wall_box(Vector3(-2.7, y + 1.0, -6.3), Vector3(0.04, 2.0, 1.2), Color.WHITE, Vector3.ZERO, glass)
	wall_box(Vector3(-3.6, y + 1.0, -5.7), Vector3(0.6, 2.0, 0.04), Color.WHITE, Vector3.ZERO, glass)
	decor_item("Chuveiro", CYLINDER, Vector3(0.25, 0.05, 0.25), Color("b0bec5"), Vector3(-3.5, y + 2.1, -6.6))
	wall_item("vaso_sanitario", "N", -7, -1.8, y)
	wall_item("pia_gabinete", "E", 0, -5.2, y)
	item("cesto_roupa", Vector3(-0.5, y, -3.5))
	item("balanca", Vector3(-1.3, y, -4.0))
	item("lixeira", Vector3(-0.4, y, -6.6))
	# Despensa.
	wall_item("estante", "N", -7, 0.7, y, false, ["8d6e63", "ffb300", "e53935"])
	wall_item("estante", "N", -7, 2.3, y, false, ["8d6e63", "ffb300", "e53935"])
	item("galao", Vector3(1.5, y, -6.75))
	item("caixa_papelao", Vector3(0.6, y, -4.0))
	item("caixa_papelao", Vector3(2.2, y, -4.6), 90)
	item("caixa_papelao", Vector3(2.2, y + 0.4, -4.6), 75)
	for x in [2.25, 2.48, 2.71]:
		item("pote_conserva", Vector3(x, y, -3.4))


func _furnish_kitchen() -> void:
	var y := GROUND
	wall_item("bancada", "N", -7, 3.75, y, true)
	wall_item("pia_cozinha", "N", -7, 5.5, y, true)
	wall_item("fogao", "N", -7, 6.75, y)
	wall_item("bancada", "N", -7, 7.7, y, true)
	wall_item("geladeira", "N", -7, 8.75, y)
	item("micro_ondas", Vector3(7.7, y + 0.9, -6.6))
	item("panela", Vector3(3.75, y + 0.9, -6.6), 30)
	wall_item("armario", "E", 12, -6.2, y)
	wall_item("armario", "E", 12, -5.3, y)
	wall_item("bancada", "E", 12, -1.0, y, true)
	item("micro_ondas", Vector3(11.5, y + 0.9, -1.0), -90)
	# Ilha com banquetas e mesinha com cadeiras.
	decor_kind("bancada", Vector3(4.6, y, -3.4), 180)
	item("banqueta", Vector3(4.2, y, -2.6))
	item("banqueta", Vector3(5.0, y, -2.6))
	table_with_chairs("mesinha", Vector3(8.2, y, -2.8), "cadeira", [["W", 0.0], ["E", 0.0], ["S", 0.0]])
	item("lixeira", Vector3(3.4, y, -0.5))
	item("galao", Vector3(11.6, y, -2.2))
	item("galao", Vector3(11.3, y, -2.3))


func _furnish_office_and_laundry() -> void:
	var y := GROUND
	wall_item("escrivaninha", "S", 7, 5.5, y)
	item("cadeira_escritorio", Vector3(5.5, y, 5.9))
	wall_item("estante", "E", 8, 1.2, y)
	wall_item("estante", "E", 8, 2.4, y)
	wall_item("estante_baixa", "W", 3, 3.5, y)
	item("poltrona", Vector3(4.0, y, 6.2), 135, ["6d4c41", "8d6e63"])
	item("luminaria", Vector3(3.5, y, 4.6))
	item("caixa_papelao", Vector3(7.4, y, 6.4))
	item("caixa_papelao", Vector3(7.4, y + 0.4, 6.4), 20)
	item("caixa_papelao", Vector3(6.8, y, 6.5))
	item("lixeira", Vector3(7.5, y, 4.0))
	# Lavanderia.
	wall_item("maquina_lavar", "S", 7, 9.0, y)
	wall_item("secadora", "S", 7, 9.7, y)
	wall_item("tanque", "S", 7, 11.2, y, true)
	item("tabua_passar", Vector3(9.5, y, 2.0))
	item("cesto_roupa", Vector3(8.5, y, 0.5))
	item("cesto_roupa", Vector3(11.5, y, 5.5))
	wall_item("armario", "W", 8, 4.6, y)
	prop("Balde", CYLINDER, Vector3(0.35, 0.35, 0.35), Color("29b6f6"), Vector3(11.4, y, 2.2))


func _furnish_garage() -> void:
	var y := GROUND
	decor_kind("carro", Vector3(15.5, y, 3.0))
	wall_item("bancada", "E", 19, 0.0, y, true, ["8d6e63", "6d4c41", "6d4c41"])
	wall_item("bancada", "E", 19, 1.25, y, true, ["8d6e63", "6d4c41", "6d4c41"])
	wall_item("prateleira_metal", "N", -1, 13.2, y, true)
	wall_item("geladeira", "W", 12, 1.0, y, false, ["eceff1", "757575"])
	for i in 3:
		item("pneu", Vector3(18.4, y + i * 0.21, 6.3))
	item("pneu", Vector3(17.7, y, 6.4))
	item("bicicleta", Vector3(13.0, y, 5.6))
	item("cortador_grama", Vector3(18.0, y, 4.0), -90)
	item("carrinho_mao", Vector3(13.2, y, 2.6))
	item("escada_abrir", Vector3(18.5, y, 2.6), -90)
	for x in [14.0, 14.3, 16.8]:
		item("lata_tinta", Vector3(x, y, -0.6))
	item("caixa_papelao", Vector3(17.2, y, -0.6))
	item("caixa_papelao", Vector3(17.8, y, -0.6))
	item("caixa_papelao", Vector3(17.5, y + 0.4, -0.6), 10)
	item("galao", Vector3(12.4, y, 6.6))


func _furnish_yards() -> void:
	var y := GROUND
	# Quintal.
	item("casinha_cachorro", Vector3(-11, y, -14), 45)
	item("churrasqueira", Vector3(6, y, -12))
	table_with_chairs("mesa_jardim", Vector3(0, y, -13), "cadeira_plastica",
		[["N", 0.0], ["S", 0.0], ["W", 0.0], ["E", 0.0]])
	table_with_chairs("mesa_jardim", Vector3(10, y, -15), "cadeira_plastica", [["W", 0.0], ["E", 0.0]])
	decor_kind("guarda_sol", Vector3(-3.5, y, -15))
	item("cadeira_plastica", Vector3(-4.1, y, -13.5), 160)
	item("cadeira_plastica", Vector3(-2.9, y, -13.5), -160)
	for at in [Vector3(-7, y, -8), Vector3(4.5, y, -8), Vector3(10, y, -9), Vector3(-12.5, y, -9.5),
			Vector3(15, y, -5), Vector3(20, y, -3), Vector3(-5, y, 9), Vector3(5, y, 9.5)]:
		item("anao_jardim", at, randf_range(-60, 60))
	for at in [Vector3(-1.6, y, -7.7), Vector3(8.3, y, -7.7), Vector3(13, y, -6.5), Vector3(20.3, y, -6.5),
			Vector3(-2.4, y, 7.6), Vector3(0.4, y, 7.6)]:
		item("vaso_planta", at)
	item("lixeira", Vector3(11.4, y, -7.7))
	item("lixeira", Vector3(12.8, y, -1.6))
	item("lixeira", Vector3(20.2, y, 10.2))
	item("carrinho_mao", Vector3(-9, y, -16), 70)
	item("bicicleta", Vector3(18, y, -9), 30, ["e53935", "212121"])
	item("pneu", Vector3(20.3, y, -12))
	for at in [Vector3(-8, y, 8.5), Vector3(-10, y, 8.4), Vector3(6, y, 8.3), Vector3(8, y, 8.5),
			Vector3(-13.2, y, -2), Vector3(-13.2, y, 2)]:
		prop("Arbusto", SPHERE, Vector3(0.75, 0.75, 0.75), Color("43a047"), at)
	for at in [Vector3(-7, y, -15.5), Vector3(14, y, -14), Vector3(18.5, y, -15)]:
		decor_item("Tronco", CYLINDER, Vector3(0.35, 2.2, 0.35), Color("6d4c41"), at)
		decor_item("Copa", SPHERE, Vector3(2.6, 2.6, 2.6), Color("2e7d32"), at + Vector3(0, 2.2, 0))


func _furnish_master_bedroom() -> void:
	var y := UPPER
	wall_item("cama_casal", "N", -7, -9.0, y)
	for x in [-10.15, -7.85]:
		wall_item("criado_mudo", "N", -7, x, y)
		item("abajur", Vector3(x, y + 0.55, -6.6))
	wall_item("guarda_roupa", "E", -3, -5.0, y)
	wall_item("guarda_roupa", "E", -3, -3.2, y)
	wall_item("comoda", "W", -12, -3.5, y)
	wall_item("penteadeira", "S", 0, -9.5, y)
	item("banqueta", Vector3(-9.5, y, -1.0), 0, ["fafafa", "f48fb1"])
	item("poltrona", Vector3(-3.7, y, -1.5), -135, ["f48fb1", "f8bbd0"])
	item("cesto_roupa", Vector3(-11.5, y, -0.5))
	item("mala", Vector3(-11.5, y, -6.6))
	item("mala", Vector3(-11.0, y, -6.6), 0, ["c62828", "212121"])
	item("vaso_planta_alto", Vector3(-6.0, y, -0.5))


func _furnish_tub_bathroom() -> void:
	var y := UPPER
	wall_item("banheira", "N", -7, -1.0, y)
	wall_item("vaso_sanitario", "E", 3, -5.0, y)
	wall_item("pia_gabinete", "W", -3, -3.6, y)
	wall_item("pia_gabinete", "W", -3, -2.7, y)
	item("balanca", Vector3(1.5, y, -2.0))
	for at in [Vector3(2.4, y, -1.0), Vector3(0.9, y, -6.0), Vector3(-2.5, y, -0.6)]:
		item("patinho", at, randf_range(0, 360))
	item("cesto_roupa", Vector3(2.5, y, -6.6))
	item("lixeira", Vector3(0.8, y, -0.5))


func _furnish_kids_room() -> void:
	var y := UPPER
	wall_item("cama_solteiro", "N", -7, 10.5, y)
	wall_item("criado_mudo", "N", -7, 11.55, y)
	wall_item("escrivaninha", "W", 3, -3.5, y)
	item("cadeira_escritorio", Vector3(4.3, y, -3.5), -90, ["37474f", "e53935"])
	wall_item("estante_baixa", "S", 0, 8.0, y)
	wall_item("estante_baixa", "S", 0, 9.0, y)
	wall_item("bau", "N", -7, 7.5, y, false, ["1e88e5", "1565c0", "ffca28"])
	wall_item("armario", "E", 12, -1.0, y, false, ["90caf9", "1565c0"])
	item("pufe", Vector3(6.5, y, -3.0), 0, ["43a047", "81c784"])
	item("cubo_brinquedo", Vector3(6.5, y, -1.0))
	item("cubo_brinquedo", Vector3(6.5, y + 0.36, -1.0), 15, ["1e88e5", "fff176"])
	item("cubo_brinquedo", Vector3(7.0, y, -1.0), 0, ["43a047", "fff176"])
	item("skate", Vector3(9.0, y, -3.5), 30)
	item("urso", Vector3(3.6, y, -6.5), 30)
	prop("Bola", SPHERE, Vector3(0.3, 0.3, 0.3), Color("fdd835"), Vector3(7.5, y, -2.0))
	prop("Bola", SPHERE, Vector3(0.3, 0.3, 0.3), Color("1e88e5"), Vector3(5.5, y, -5.5))


func _furnish_baby_room() -> void:
	var y := UPPER
	wall_item("berco", "S", 7, -10.5, y)
	wall_item("trocador", "E", -4, 5.5, y)
	item("poltrona", Vector3(-5.4, y, 3.3), 180, ["ffcc80", "ffe0b2"])
	wall_item("comoda", "W", -12, 6.0, y, false, ["fafafa", "ffcc80"])
	for at in [Vector3(-11.5, y, 2.5), Vector3(-10.9, y, 2.5), Vector3(-8.0, y, 6.6), Vector3(-4.5, y, 6.6)]:
		item("ursinho", at, randf_range(-40, 40))
	item("cubo_brinquedo", Vector3(-9.0, y, 3.0), 0, ["f48fb1", "fff176"])
	item("cubo_brinquedo", Vector3(-8.6, y, 3.0), 0, ["80deea", "fff176"])
	item("cesto_fraldas", Vector3(-6.0, y, 6.6))
	item("cesto_fraldas", Vector3(-6.6, y, 6.6))
	item("cavalinho", Vector3(-7.5, y, 4.2), 60)


func _furnish_family_room_and_guest_room() -> void:
	var y := UPPER
	wall_item("sofa2", "W", -4, 4.5, y, false, ["43a047", "81c784"])
	wall_item("estante", "E", MAIN_STAIR_HOLE.position.x, 4.5, y)
	item("poltrona", Vector3(-1.0, y, 6.2), 180)
	item("mesa_lateral", Vector3(-3.5, y, 6.5))
	item("abajur", Vector3(-3.5, y + 0.54, 6.5))
	item("luminaria", Vector3(1.3, y, 6.6))
	item("pufe", Vector3(-2.0, y, 3.0))
	item("vaso_planta_alto", Vector3(-3.5, y, 2.5))
	# Quarto de hóspedes (com cantinho de costura).
	wall_item("cama_solteiro", "E", 12, 5.0, y, false, ["5d4037", "ffcc80", "fafafa"])
	wall_item("criado_mudo", "E", 12, 6.4, y)
	wall_item("guarda_roupa", "W", 3, 4.5, y)
	item("manequim", Vector3(5.0, y, 6.3))
	wall_item("escrivaninha", "S", 7, 7.5, y, false, ["fafafa", "eceff1"])
	item("cadeira", Vector3(7.5, y, 5.8))
	item("mala", Vector3(11.5, y, 2.5))
	item("mala", Vector3(11.0, y, 2.5), 0, ["2e7d32", "212121"])
	item("caixa_papelao", Vector3(4.0, y, 6.5))
	# Corredor de cima.
	wall_item("estante_baixa", "N", 0, -9.5, y)
	item("vaso_planta_alto", Vector3(11.5, y, 1.0))
	item("vaso_planta_alto", Vector3(-11.5, y, 1.0))
	item("cesto_roupa", Vector3(9.6, y, 0.5))


func _furnish_attic() -> void:
	var y := ATTIC
	# Itens altos perto da cumeeira; baixos perto das muretas.
	item("movel_coberto_alto", Vector3(-9.5, y, -1.0))
	item("movel_coberto_alto", Vector3(6.5, y, 1.5), 90)
	item("movel_coberto", Vector3(-8.0, y, 2.5), 20)
	item("movel_coberto", Vector3(3.5, y, -2.5), -10)
	item("movel_coberto", Vector3(9.5, y, -2.0))
	item("manequim", Vector3(-3.0, y, -0.8))
	item("cavalinho", Vector3(1.0, y, 2.6), -30)
	item("cadeira_balanco", Vector3(-1.0, y, -2.5), 150)
	for at in [Vector3(-11.0, y, 3.8), Vector3(-6.0, y, -3.8), Vector3(5.0, y, 3.8), Vector3(10.5, y, 3.6)]:
		item("bau", at, 180.0 if at.z > 0 else 0.0)
	for at in [Vector3(-11.2, y, -3.6), Vector3(-10.6, y, -3.6), Vector3(2.0, y, -3.8), Vector3(8.0, y, 4.1)]:
		item("mala", at, 90)
	for at in [Vector3(0.5, y, -4.2), Vector3(1.05, y, -4.2), Vector3(0.75, y + 0.4, -4.2), Vector3(-4.5, y, 4.2),
			Vector3(11.4, y, -4.2), Vector3(11.4, y + 0.4, -4.2), Vector3(7.0, y, -4.2)]:
		item("caixa_papelao", at)
	for at in [Vector3(-7.5, y, -4.0), Vector3(-2.5, y, 4.1), Vector3(8.5, y, -4.1)]:
		item("caixa_natal", at)
	item("quadro_coberto", Vector3(-11.5, y, 0.5), 90)
	item("quadro_coberto", Vector3(11.5, y, 0.0), -90)
	item("quadro_coberto", Vector3(4.5, y, -0.3))
	item("rolo_tapete", Vector3(0.0, y, 0.6))
	item("rolo_tapete", Vector3(-6.0, y, 3.9), 0, ["1e88e5", "fff176"])
	item("urso", Vector3(-4.0, y, 3.0), -40)
	item("abajur", Vector3(9.0, y, 3.2))
	item("luminaria", Vector3(-1.5, y, -1.6))


func _furnish_basement() -> void:
	var y := BASEMENT
	# Parte leste: sinuca, academia, depósito.
	decor_kind("mesa_sinuca", Vector3(-1.5, y, -4.0))
	decor_kind("caldeira", Vector3(3.3, y, -6.3))
	wall_item("freezer", "N", -7, 1.2, y)
	wall_item("prateleira_metal", "E", 4, -4.0, y, true)
	wall_item("geladeira", "E", 4, -2.6, y, false, ["eceff1", "757575"])
	item("fogao", Vector3(-5.2, y, -6.3), 0, ["d7ccc8", "212121", "9e9e9e"])
	item("bicicleta_ergometrica", Vector3(-5.0, y, -1.8), 90)
	item("movel_coberto", Vector3(-4.6, y, -4.2), 90)
	item("movel_coberto", Vector3(2.5, y, -2.0))
	item("movel_coberto_alto", Vector3(-6.4, y, -0.3), 90)
	item("cadeira_balanco", Vector3(-0.5, y, -1.8), 20)
	for at in [Vector3(-3.4, y, -6.6), Vector3(-2.85, y, -6.6), Vector3(-3.1, y + 0.4, -6.6)]:
		item("caixa_papelao", at)
	item("caixa_natal", Vector3(-6.4, y, -6.5))
	# Adega e despensa (oeste).
	for x in [-11.4, -10.8, -10.2]:
		for z in [-6.5, -5.85]:
			item("barril_pequeno", Vector3(x, y, z))
	wall_item("prateleira_metal", "E", -7, 0.2, y, true, ["78909c", "b0bec5", "c62828", "fbc02d"])
	wall_item("prateleira_metal", "W", -12, -1.0, y, true, ["78909c", "b0bec5", "c62828", "fbc02d"])
	for at in [Vector3(-10.5, y, 0.6), Vector3(-10.3, y, 0.6), Vector3(-10.1, y, 0.6), Vector3(-8.0, y, -6.6),
			Vector3(-7.8, y, -6.6), Vector3(-9.0, y, -2.5)]:
		item("pote_conserva", at)
	item("movel_coberto", Vector3(-9.5, y, -3.5), 15)
	item("bau", Vector3(-11.4, y, -3.0), 90)
	item("galao", Vector3(-7.6, y, -1.0))


func _add_lights() -> void:
	var warm := Color("ffe0b2")
	for at in [Vector3(-8, 2.6, 3.5), Vector3(-8, 2.6, -3.5), Vector3(-0.5, 2.6, 4.5), Vector3(-0.5, 2.6, -1.0),
			Vector3(-2, 2.6, -5), Vector3(1.5, 2.6, -5), Vector3(7.5, 2.6, -3.5), Vector3(5.5, 2.6, 3.5),
			Vector3(10, 2.6, 3.5), Vector3(15.5, 2.6, 3)]:
		add_light(lights, at, 7.0, 0.8)
	for at in [Vector3(-7.5, 5.8, -3.5), Vector3(0, 5.8, -3.5), Vector3(7.5, 5.8, -3.5), Vector3(-8, 5.8, 4.5),
			Vector3(-1, 5.8, 4.5), Vector3(7.5, 5.8, 4.5), Vector3(-6, 5.8, 1.0), Vector3(6, 5.8, 1.0)]:
		add_light(lights, at, 7.0, 0.8)
	for at in [Vector3(-8, 8.2, 0), Vector3(0, 8.2, 0), Vector3(8, 8.2, 0)]:
		add_light(lights, at, 8.0, 0.6, warm)
	for at in [Vector3(-9.5, -0.8, -3), Vector3(-2, -0.8, -3), Vector3(2.5, -0.8, -5)]:
		add_light(lights, at, 7.0, 0.55, Color("ffcc80"))
