extends SceneTree
## Base dos geradores de mapa (tools/build_*.gd). Cada gerador estende este
## script, sobrescreve `_build()` e define `out_path`.
## Uso: godot --headless --path . -s res://tools/build_<mapa>.gd [-- --out=res://outro.tscn]
## ATENÇÃO: sobrescreve a cena. Depois de editar o mapa no editor, não rode de novo.

const PROP_SCENE := preload("res://scenes/props/prop.tscn")
const WALL_THICKNESS := 0.2
## Larguras livres padrão das passagens (o alien tem 0,7 m de largura).
const DOOR := 1.1
const MAIN_DOOR := 1.4
const DOOR_TOP := 2.3
## Passagens mais estreitas que isso geram aviso no relatório.
const MIN_PASSAGE := 1.0
## Lado (m) dos blocos em que paredes, pisos e forros são assados. O Compatibility
## (web) e o Mobile aplicam no máximo 8 luzes por malha: uma malha única para todas
## as paredes perde quase todas as luzes, um bloco pequeno só pega as da vizinhança.
const CHUNK_SIZE := 8.0
## Deslocamento da grade dos blocos, para os cortes não caírem na face de uma parede.
const CHUNK_OFFSET := 0.05
## Luzes por malha que o Mobile e o Compatibility aplicam.
const MAX_LIGHTS_PER_MESH := 8
## Grupos cujas caixas CSG (pisos e forros) entram nos blocos junto com as paredes.
const BAKED_GROUPS := ["Floors", "Ceilings"]
## Pisos com um lado maior que isso (gramados) ficam fora dos blocos.
const MAX_BAKED_FLOOR := 40.0
## Primeira camada de render dos andares (com `chunk_levels`): os blocos de cada
## andar ficam numa camada e as luzes só iluminam os blocos do próprio andar.
const STOREY_FIRST_LAYER := 11

const BOX := PropBuilder.Shape.BOX
const CYLINDER := PropBuilder.Shape.CYLINDER
const CONE := PropBuilder.Shape.CONE
const SPHERE := PropBuilder.Shape.SPHERE
const CAPSULE := PropBuilder.Shape.CAPSULE
const PRISM := PropBuilder.Shape.PRISM

## Nome mostrado na mira para as primitivas disfarçáveis, pelo nome base do nó.
## Toda primitiva criada com `prop()` precisa ter uma entrada aqui.
const PRIMITIVE_LABELS := {
	"Abobora": "Abóbora",
	"Arbusto": "Arbusto",
	"Balde": "Balde",
	"Bola": "Bola",
	"BolaGolfe": "Bola de golfe",
	"BolaGrande": "Bola grande",
	"Bolinha": "Bolinha",
	"Garrafa": "Garrafa",
	"Lapide": "Lápide",
	"Lata": "Lata",
	"Patinho": "Patinho",
	"Produto": "Caixa pequena",
}

var out_path := ""
var map_name := "Mapa"
var root_name := "Map"
var wall_height := 3.0
## Alturas em que os blocos também são cortados (nas lajes, entre os andares). Cada
## andar fica com sua camada de render, e as luzes não atravessam as lajes.
var chunk_levels: Array[float] = []

var map_root: Node3D
var props: Node3D
var decor: Node3D
## Paredes enquanto o mapa é montado; no fim viram blocos assados (`_bake_structure`).
var walls: CSGCombiner3D
## Rampas invisíveis das escadas e degraus só visuais (criados sob demanda).
var ramps: Node3D
var steps: Node3D
var _name_counts := {}
## AABBs de objetos e paredes, usados para avisar sobre sobreposições.
var _bounds: Array[Dictionary] = []
## Corredores das passagens (caixa livre de cada porta), conferidos no relatório.
var _passages: Array[Dictionary] = []
## Forros criados com `add_ceiling` (no bloco do andar de baixo da laje).
var _ceiling_pieces: Array[CSGShape3D] = []
## Material dos blocos assados com a cor nos vértices (criado sob demanda).
var _vertex_color_material: StandardMaterial3D


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_path = arg.substr(6)
	# O CSG só é calculado no frame seguinte, então a geração roda numa corrotina.
	_generate.call_deferred()


func _generate() -> void:
	map_root = Node3D.new()
	map_root.name = root_name
	map_root.set_script(load("res://scenes/maps/map_base.gd"))
	map_root.set("map_name", map_name)
	walls = CSGCombiner3D.new()
	walls.name = "Walls"
	walls.use_collision = true
	decor = Node3D.new()
	decor.name = "Decor"
	props = Node3D.new()
	props.name = "Props"

	_build()

	_report_overlaps()
	_report_passages()
	await _bake_structure()
	_set_owner_recursive(map_root)
	var packed := PackedScene.new()
	var err := packed.pack(map_root)
	if err == OK:
		err = ResourceSaver.save(packed, out_path)
	print("%s salvo: %s | objetos disfarçáveis: %d | decoração: %d" % [
		out_path, error_string(err), props.get_child_count(), decor.get_child_count()])
	map_root.free()
	quit()


## Sobrescrito por cada gerador.
func _build() -> void:
	pass


# --- Estrutura ---------------------------------------------------------------

## Retorna o Environment criado, para cada mapa ajustar névoa, brilho etc.
## O sol fica no nó "Sun".
func add_environment(sky_top: Color, sky_horizon: Color, ambient_energy := 0.9, sun_energy := 1.1) -> Environment:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = sky_top
	sky_material.sky_horizon_color = sky_horizon
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = ambient_energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	map_root.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	map_root.add_child(sun)
	return env


## Adiciona os grupos de paredes, decoração e objetos na ordem da cena.
func add_content_groups() -> void:
	map_root.add_child(walls)
	map_root.add_child(decor)
	map_root.add_child(props)


## Laje com vãos (escadas): piso do andar de cima e teto do andar de baixo.
## `top` é a altura da face de cima; a laje tem 0,2 m de espessura.
func add_slab(parent: Node, slab_name: String, rect: Rect2, top: float, color: Color, holes: Array = []) -> void:
	var pieces: Array[Rect2] = [rect]
	for hole: Rect2 in holes:
		var next: Array[Rect2] = []
		for piece in pieces:
			next.append_array(_subtract_rect(piece, hole))
		pieces = next
	for i in pieces.size():
		add_floor(parent, "%s%d" % [slab_name, i + 1], pieces[i], color, top)


## Forro só visual (sem colisão) colado embaixo da altura `bottom` (a face de baixo
## da laje), para o teto não mostrar a cor do piso de cima. Fica 2 cm abaixo da laje:
## com as faces na mesma altura, o Compatibility e o Mobile mostram as duas piscando.
func add_ceiling(parent: Node, ceiling_name: String, rect: Rect2, bottom: float, color: Color, holes: Array = []) -> void:
	var pieces: Array[Rect2] = [rect]
	for hole: Rect2 in holes:
		var next: Array[Rect2] = []
		for piece in pieces:
			next.append_array(_subtract_rect(piece, hole))
		pieces = next
	for i in pieces.size():
		var box := CSGBox3D.new()
		box.name = "%s%d" % [ceiling_name, i + 1]
		box.size = Vector3(pieces[i].size.x, 0.02, pieces[i].size.y)
		box.position = Vector3(pieces[i].get_center().x, bottom - 0.01, pieces[i].get_center().y)
		box.material = PropBuilder.get_material(color)
		parent.add_child(box)
		_ceiling_pieces.append(box)


func add_floor(parent: Node, floor_name: String, rect: Rect2, color: Color, top := 0.0, collision := true) -> void:
	var box := CSGBox3D.new()
	box.name = floor_name
	box.size = Vector3(rect.size.x, 0.2, rect.size.y)
	box.position = Vector3(rect.get_center().x, top - 0.1, rect.get_center().y)
	box.use_collision = collision
	box.material = PropBuilder.get_material(color)
	parent.add_child(box)


## Parede ao longo de X. Cada vão é [centro, largura] (vão até o teto) ou
## [centro, largura, peitoril, topo]: porta com verga (peitoril 0) ou janela.
func wall_x(z: float, x0: float, x1: float, gaps: Array, color: Color, height := -1.0, base := 0.0,
		material: Material = null) -> void:
	var h := wall_height if height < 0.0 else height
	for segment in _segments(x0, x1, gaps):
		wall_box(Vector3((segment.x + segment.y) * 0.5, base + h * 0.5, z),
			Vector3(segment.y - segment.x + WALL_THICKNESS, h, WALL_THICKNESS), color, Vector3.ZERO, material)
	for gap in gaps:
		for piece in _gap_fillers(gap, h):
			wall_box(Vector3(gap[0], base + (piece.x + piece.y) * 0.5, z),
				Vector3(gap[1], piece.y - piece.x, WALL_THICKNESS), color, Vector3.ZERO, material)
		_add_passage(gap, h, Vector3(gap[0], base, z), Vector3.RIGHT)


## Parede ao longo de Z. Vãos como em `wall_x`.
func wall_z(x: float, z0: float, z1: float, gaps: Array, color: Color, height := -1.0, base := 0.0,
		material: Material = null) -> void:
	var h := wall_height if height < 0.0 else height
	for segment in _segments(z0, z1, gaps):
		wall_box(Vector3(x, base + h * 0.5, (segment.x + segment.y) * 0.5),
			Vector3(WALL_THICKNESS, h, segment.y - segment.x + WALL_THICKNESS), color, Vector3.ZERO, material)
	for gap in gaps:
		for piece in _gap_fillers(gap, h):
			wall_box(Vector3(x, base + (piece.x + piece.y) * 0.5, gap[0]),
				Vector3(WALL_THICKNESS, piece.y - piece.x, gap[1]), color, Vector3.ZERO, material)
		_add_passage(gap, h, Vector3(x, base, gap[0]), Vector3.BACK)


## Escada de `bottom` (pé da escada, no piso) até `top` (borda do patamar, no
## piso de cima). A colisão é uma rampa invisível, porque o CharacterBody3D não
## sobe degraus, mais uma cunha sólida embaixo dela; os degraus são só visuais.
## Retorna o número de degraus.
func stairs(bottom: Vector3, top: Vector3, width: float, color: Color) -> int:
	if ramps == null:
		ramps = add_group("Ramps")
		steps = add_group("Steps")
	var flat := Vector3(top.x - bottom.x, 0.0, top.z - bottom.z)
	var run := flat.length()
	var rise := top.y - bottom.y
	var count := maxi(1, roundi(rise / 0.18))
	var riser := rise / count
	var tread := run / count
	var yaw := atan2(flat.x, flat.z)
	var basis := Basis(Vector3.UP, yaw)
	for i in count:
		var step := CSGBox3D.new()
		step.name = "Degrau%d" % (steps.get_child_count() + 1)
		step.size = Vector3(width, riser * (i + 1), tread)
		step.position = bottom + basis * Vector3(0.0, riser * (i + 1) * 0.5, tread * (i + 0.5))
		step.rotation.y = yaw
		step.material = PropBuilder.get_material(color)
		steps.add_child(step)
	# Rampa meio degrau acima da linha dos degraus; o começo fica enterrado no piso.
	var slope := atan2(rise, run)
	var extra := 0.6
	var length := sqrt(run * run + rise * rise) + extra
	var thickness := 0.3
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, thickness, length)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = "Rampa%d" % (ramps.get_child_count() / 2 + 1)
	body.add_child(collision)
	var along := basis * Vector3(0, sin(slope), cos(slope))
	var normal := basis * Vector3(0, cos(slope), -sin(slope))
	var mid := (bottom + top) * 0.5 - along * (extra * 0.5) + Vector3.UP * riser * 0.5
	body.transform = Transform3D(basis * Basis(Vector3.RIGHT, -slope), mid - normal * thickness * 0.5)
	ramps.add_child(body)
	# Cunha sólida embaixo da rampa, com o mesmo volume dos degraus. Sem ela sobra
	# um vão oco sob a parte alta da escada, onde dá para entrar pela lateral.
	var half := width * 0.5
	var wedge := ConvexPolygonShape3D.new()
	wedge.points = PackedVector3Array([
		Vector3(-half, 0, 0), Vector3(half, 0, 0),
		Vector3(-half, 0, run), Vector3(half, 0, run),
		Vector3(-half, rise, run), Vector3(half, rise, run),
	])
	var wedge_shape := CollisionShape3D.new()
	wedge_shape.shape = wedge
	var base := StaticBody3D.new()
	base.name = "BaseEscada%d" % ((ramps.get_child_count() + 1) / 2)
	base.add_child(wedge_shape)
	base.transform = Transform3D(basis, bottom)
	ramps.add_child(base)
	return count


## Caixa sólida dentro do combinador de paredes (pilares, plataformas, rampas...).
func wall_box(center: Vector3, size: Vector3, color: Color, rotation_degrees := Vector3.ZERO,
		material: Material = null) -> CSGBox3D:
	var box := CSGBox3D.new()
	box.name = "Parede%d" % walls.get_child_count()
	box.position = center
	box.size = size
	box.rotation_degrees = rotation_degrees
	box.material = material if material else PropBuilder.get_material(color)
	walls.add_child(box)
	if rotation_degrees == Vector3.ZERO:
		_bounds.append({"name": box.name, "aabb": AABB(center - size * 0.5, size), "wall": true})
	return box


## Sala de contagem fechada (fora do mapa) com piso próprio.
func add_seeker_cage(parent: Node, center: Vector3, size := Vector2(4, 4), color := Color("546e7a")) -> void:
	var half := size * 0.5
	add_floor(parent, "PisoContagem", Rect2(center.x - half.x, center.z - half.y, size.x, size.y), Color("37474f"))
	wall_x(center.z - half.y, center.x - half.x, center.x + half.x, [], color, 3.0)
	wall_x(center.z + half.y, center.x - half.x, center.x + half.x, [], color, 3.0)
	wall_z(center.x - half.x, center.z - half.y, center.z + half.y, [], color, 3.0)
	wall_z(center.x + half.x, center.z - half.y, center.z + half.y, [], color, 3.0)


func add_markers(hider_spawns: Array, seeker_cage: Vector3, seeker_release: Vector3) -> void:
	var spawns := add_group("HiderSpawns")
	for i in hider_spawns.size():
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % (i + 1)
		marker.position = hider_spawns[i]
		spawns.add_child(marker)
	_marker("SeekerCage", seeker_cage)
	_marker("SeekerRelease", seeker_release)


func add_group(group_name: String, parent: Node = null) -> Node3D:
	var node := Node3D.new()
	node.name = group_name
	(parent if parent else map_root).add_child(node)
	return node


## Esfera ou caixa luminosa sem colisão (lâmpadas, letreiros).
func add_glow(parent: Node, glow_name: String, at: Vector3, size: Vector3, color: Color, sphere := false) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.5
	var shape: CSGPrimitive3D
	if sphere:
		var ball := CSGSphere3D.new()
		ball.radius = size.x * 0.5
		ball.radial_segments = 8
		ball.rings = 4
		shape = ball
	else:
		var box := CSGBox3D.new()
		box.size = size
		shape = box
	shape.name = "%s%d" % [glow_name, parent.get_child_count() + 1]
	shape.position = at
	shape.material = material
	parent.add_child(shape)


func add_light(parent: Node, at: Vector3, light_range: float, energy: float, color := Color("fff3e0")) -> void:
	var light := OmniLight3D.new()
	light.name = "Luz%d" % (parent.get_child_count() + 1)
	light.position = at
	light.omni_range = light_range
	light.light_energy = energy
	light.light_color = color
	parent.add_child(light)


# --- Objetos -------------------------------------------------------------------
# Decoração (`decor_item`) não pode ser copiada; objetos (`prop`) podem.
# A posição é a base do objeto.

## Objeto do catálogo que pode ser copiado. `colors` troca as cores dos slots.
func item(kind: String, at: Vector3, yaw := 0.0, colors := []) -> Prop:
	return _spawn_item(props, kind, at, yaw, colors, true)


## Objeto do catálogo que só enfeita (bancadas, carro, sinuca...).
func decor_kind(kind: String, at: Vector3, yaw := 0.0, colors := []) -> Prop:
	return _spawn_item(decor, kind, at, yaw, colors, false)


func _spawn_item(parent: Node, kind: String, at: Vector3, yaw: float, colors: Array, disguisable: bool) -> Prop:
	assert(PropCatalog.has_kind(kind), "Objeto fora do catálogo: " + kind)
	var instance: Prop = PROP_SCENE.instantiate()
	var base_name := kind.to_pascal_case()
	_name_counts[base_name] = _name_counts.get(base_name, 0) + 1
	instance.name = "%s%d" % [base_name, _name_counts[base_name]]
	instance.kind = kind
	instance.colors = PackedColorArray(colors.map(func(c) -> Color: return Color(c)))
	instance.disguisable = disguisable
	instance.position = at
	instance.rotation_degrees.y = yaw
	parent.add_child(instance)
	# Uma caixa por forma de colisão: o vão embaixo de mesas e guarda-sóis não conta.
	for entry in PropBuilder.make_item_shapes(kind):
		var box := entry[0] as BoxShape3D
		var local := AABB(-box.size * 0.5, box.size)
		var transformed: AABB = entry[1] * local
		_bounds.append({"name": instance.name, "aabb": _rotated_bounds(transformed, at, yaw), "wall": false,
			"decor": not disguisable})
	return instance


## Encosta um objeto do catálogo numa parede. `side`: "N" (parede em z menor),
## "S", "W" ou "E"; `wall` é a coordenada da parede e `along`, a posição ao longo dela.
func wall_item(kind: String, side: String, wall: float, along: float, y: float, decor := false, colors := []) -> void:
	var back := -PropBuilder.item_bounds(kind).position.z + WALL_THICKNESS * 0.5 + 0.02
	var at: Vector3
	var yaw := 0.0
	match side:
		"N":
			at = Vector3(along, y, wall + back)
		"S":
			at = Vector3(along, y, wall - back)
			yaw = 180.0
		"W":
			at = Vector3(wall + back, y, along)
			yaw = 90.0
		"E":
			at = Vector3(wall - back, y, along)
			yaw = -90.0
	if decor:
		decor_kind(kind, at, yaw, colors)
	else:
		item(kind, at, yaw, colors)


## Mesa com cadeiras em volta (as cadeiras ficam do lado de fora do tampo).
func table_with_chairs(table: String, center: Vector3, chair: String, sides: Array) -> void:
	item(table, center)
	var bounds := PropBuilder.item_bounds(table)
	var chair_depth := PropBuilder.item_bounds(chair).size.z
	for spec in sides:
		# spec: [lado ("N", "S", "W", "E"), deslocamento ao longo do lado]
		var gap := chair_depth * 0.5 + 0.05
		match spec[0]:
			"N":
				item(chair, center + Vector3(spec[1], 0, bounds.position.z - gap), 0)
			"S":
				item(chair, center + Vector3(spec[1], 0, bounds.end.z + gap), 180)
			"W":
				item(chair, center + Vector3(bounds.position.x - gap, 0, spec[1]), 90)
			"E":
				item(chair, center + Vector3(bounds.end.x + gap, 0, spec[1]), -90)


func prop(base_name: String, shape: int, size: Vector3, color: Color, at: Vector3, yaw := 0.0) -> void:
	_spawn(props, base_name, shape, size, color, at, yaw, true)


func decor_item(base_name: String, shape: int, size: Vector3, color: Color, at: Vector3, yaw := 0.0) -> void:
	_spawn(decor, base_name, shape, size, color, at, yaw, false)


func _spawn(parent: Node, base_name: String, shape: int, size: Vector3, color: Color,
		at: Vector3, yaw: float, disguisable: bool) -> void:
	var item: Prop = PROP_SCENE.instantiate()
	_name_counts[base_name] = _name_counts.get(base_name, 0) + 1
	item.name = "%s%d" % [base_name, _name_counts[base_name]]
	item.shape = shape
	item.size = size
	item.color = color
	item.disguisable = disguisable
	if disguisable:
		item.label = PRIMITIVE_LABELS.get(base_name, "")
		if item.label == "":
			push_warning("Primitiva sem nome em PRIMITIVE_LABELS: " + base_name)
	item.position = at
	item.rotation_degrees.y = yaw
	parent.add_child(item)
	_bounds.append({"name": item.name, "aabb": _prop_aabb(shape, size, at, yaw), "wall": false, "decor": not disguisable})


## Caixa envolvente de `bounds` girada em Y e movida para `at`.
func _rotated_bounds(bounds: AABB, at: Vector3, yaw: float) -> AABB:
	var basis := Basis(Vector3.UP, deg_to_rad(yaw))
	var result := AABB(at + basis * bounds.position, Vector3.ZERO)
	for i in 8:
		result = result.expand(at + basis * bounds.get_endpoint(i))
	return result


func _prop_aabb(shape: int, size: Vector3, at: Vector3, yaw: float) -> AABB:
	var height := PropBuilder.height_of(shape, size)
	var footprint := Vector2(size.x, size.x if shape != BOX and shape != PRISM else size.z)
	# Caixa envolvente da base girada no eixo Y.
	var c := absf(cos(deg_to_rad(yaw)))
	var s := absf(sin(deg_to_rad(yaw)))
	footprint = Vector2(footprint.x * c + footprint.y * s, footprint.x * s + footprint.y * c)
	var extent := Vector3(footprint.x, height, footprint.y)
	return AABB(at - Vector3(extent.x * 0.5, 0.0, extent.z * 0.5), extent)


## Avisa sobre objetos que se atravessam (ignora contatos e pilhas).
## Paredes entre si e peças de decoração entre si (partes de um mesmo enfeite)
## não contam. Cada par de nomes aparece uma vez só.
## Porta: vão do chão até `top`, com `width` de largura livre.
func door(center: float, width := DOOR, top := DOOR_TOP) -> Array:
	return [center, width, 0.0, top]


## Registra o corredor de uma passagem (vão que começa no chão) para o relatório.
func _add_passage(gap: Array, height: float, at: Vector3, along: Vector3) -> void:
	if gap.size() >= 4 and gap[2] > 0.0:
		return
	# Vão sem verga (só largura) é aberto em cima, como uma abertura na cerca.
	var top: float = gap[3] if gap.size() >= 4 and gap[3] < height else 1.8
	var width: float = gap[1]
	# Corredor de até 1,8 m de altura e 0,5 m para cada lado da parede.
	var size := along * width + Vector3.UP * minf(top, 1.8) + (Vector3.ONE - along - Vector3.UP) * (WALL_THICKNESS + 1.0)
	_passages.append({"name": "passagem em %s" % at.snapped(Vector3.ONE * 0.1), "width": width, "top": top,
		"aabb": AABB(at + Vector3.UP * 0.05 - (size - Vector3.UP * size.y) * 0.5, size)})


func _report_passages() -> void:
	var problems := 0
	for passage in _passages:
		if passage.width < MIN_PASSAGE - 0.001 or passage.top < 1.8:
			problems += 1
			print("  passagem estreita ou baixa: %s (%.2f m livres, %.2f m de altura)" % [passage.name, passage.width, passage.top])
		# Aberturas largas (arcos, portões) continuam livres mesmo com objetos nas bordas.
		if passage.width >= 2.0:
			continue
		for other in _bounds:
			if other.wall:
				continue
			var overlap := _overlap(passage.aabb, other.aabb)
			if overlap.x > 0.03 and overlap.y > 0.03 and overlap.z > 0.03:
				problems += 1
				print("  passagem bloqueada: %s por %s" % [passage.name, other.name])
	print("passagens: %d | problemas: %d" % [_passages.size(), problems])


func _report_overlaps() -> void:
	var reported := {}
	for i in _bounds.size():
		for j in range(i + 1, _bounds.size()):
			var a: Dictionary = _bounds[i]
			var b: Dictionary = _bounds[j]
			if (a.wall and b.wall) or a.name == b.name:
				continue
			if a.get("decor", false) and b.get("decor", false):
				continue
			var overlap := _overlap(a.aabb, b.aabb)
			var key := "%s x %s" % [a.name, b.name]
			if overlap.x > 0.03 and overlap.y > 0.03 and overlap.z > 0.03 and not reported.has(key):
				reported[key] = true
				print("  sobreposição: %s (%s)" % [key, overlap.snapped(Vector3.ONE * 0.01)])
	print("sobreposições encontradas: %d" % reported.size())


# --- Estrutura assada ------------------------------------------------------------

## Troca as paredes, os pisos e os forros por blocos de CHUNK_SIZE × CHUNK_SIZE m
## (cortados também nas alturas de `chunk_levels`): cada bloco é uma malha assada
## com um StaticBody3D de colisão (camada 1, mundo) feito das peças que tinham
## colisão. Sem CSG o mapa carrega mais rápido, e cada malha só recebe as luzes
## perto dela. Pisos maiores que MAX_BAKED_FLOOR (gramados) continuam em CSG.
func _bake_structure() -> void:
	var solid: Array[CSGShape3D] = []
	solid.assign(walls.get_children())
	var visual: Array[CSGShape3D] = []
	# Pisos e forros (caixas sem rotação) entram inteiros no andar deles: o do topo
	# do piso ou o da face de baixo do forro. Assim as lajes não viram fatias.
	var flat := {}
	for group_name in BAKED_GROUPS:
		var group := map_root.get_node_or_null(group_name)
		if group == null:
			continue
		for node in group.find_children("*", "CSGShape3D", true, false):
			var piece := node as CSGShape3D
			if piece.get_parent() is CSGShape3D or not (piece is CSGBox3D or piece is CSGMesh3D):
				continue
			var size := _piece_bounds(piece).size
			if maxf(size.x, size.z) > MAX_BAKED_FLOOR:
				continue
			(solid if piece.use_collision else visual).append(piece)
			if piece is CSGBox3D and _map_transform(piece).basis.is_equal_approx(Basis.IDENTITY):
				var aabb := _piece_bounds(piece)
				var y := aabb.position.y + 0.01 if piece in _ceiling_pieces else aabb.end.y - 0.01
				flat[piece] = _chunk_of(Vector3(0, y, 0)).y
	var bounds := _piece_bounds(solid[0])
	for piece in solid + visual:
		bounds = bounds.merge(_piece_bounds(piece))
	bounds = bounds.grow(1.0)

	# Cada bloco recebe cópias das peças que encostam nele, recortadas pela caixa do
	# bloco. As faces do corte ficam com um material marcador e são descartadas
	# (estão dentro das peças); a colisão fica com elas, o que não atrapalha.
	var cut_material := StandardMaterial3D.new()
	var cells := {}
	for piece in solid + visual:
		var aabb := _piece_bounds(piece)
		var first := _chunk_of(aabb.position)
		var last := _chunk_of(aabb.end)
		if flat.has(piece):
			first.y = flat[piece]
			last.y = flat[piece]
		for x in range(first.x, last.x + 1):
			for y in range(first.y, last.y + 1):
				for z in range(first.z, last.z + 1):
					var cell: Dictionary = cells.get_or_add(Vector3i(x, y, z), {"solid": [], "visual": []})
					cell["solid" if piece in solid else "visual"].append(piece)
	var keys := cells.keys()
	keys.sort()
	var combiners: Array[Dictionary] = []
	for key: Vector3i in keys:
		var region := _chunk_bounds(key, bounds)
		var entry := {"cell": key}
		for kind in ["solid", "visual"]:
			if not cells[key][kind].is_empty():
				entry[kind] = _cut_combiner(cells[key][kind], region, cut_material, flat)
		combiners.append(entry)
	await process_frame

	var baked := Node3D.new()
	baked.name = "Walls"
	for entry in combiners:
		var surfaces: Array[Dictionary] = []
		for kind in ["solid", "visual"]:
			if entry.has(kind):
				var source: ArrayMesh = entry[kind].bake_static_mesh()
				for i in source.get_surface_count():
					if source.surface_get_material(i) != cut_material:
						surfaces.append({"arrays": source.surface_get_arrays(i), "material": source.surface_get_material(i)})
		var mesh := _block_mesh(surfaces)
		if mesh.get_surface_count() > 0:
			var block := MeshInstance3D.new()
			block.name = "Bloco%d" % (baked.get_child_count() + 1)
			block.mesh = mesh
			if not chunk_levels.is_empty():
				block.layers = _storey_layer(entry.cell.y)
			baked.add_child(block)
			if entry.has("solid"):
				var shape := CollisionShape3D.new()
				shape.name = "Forma"
				shape.shape = entry.solid.bake_collision_shape()
				var body := StaticBody3D.new()
				body.name = "Colisao"
				body.add_child(shape)
				block.add_child(body)
		for kind in ["solid", "visual"]:
			if entry.has(kind):
				entry[kind].free()

	var index := walls.get_index()
	map_root.remove_child(walls)
	walls.free()
	for piece in solid + visual:
		if is_instance_valid(piece):
			piece.free()
	for group_name in BAKED_GROUPS:
		var group := map_root.get_node_or_null(group_name)
		if group:
			_free_empty_groups(group)
	map_root.add_child(baked)
	map_root.move_child(baked, index)
	if not chunk_levels.is_empty():
		_limit_lights_to_storeys()
	_report_lights(baked)


## Cada luz ilumina só os blocos do seu andar (as outras camadas continuam todas).
func _limit_lights_to_storeys() -> void:
	var storeys := 0
	for level in chunk_levels.size() + 1:
		storeys |= _storey_layer(level)
	for node in map_root.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light is OmniLight3D or light is SpotLight3D:
			var level := _chunk_of(_map_transform(light).origin).y
			light.light_cull_mask = (light.light_cull_mask & ~storeys) | _storey_layer(level)


func _storey_layer(level: int) -> int:
	return 1 << (STOREY_FIRST_LAYER - 1 + level)


## Combinador (já na árvore, para o CSG ser calculado) com cópias de `pieces`
## recortadas pela caixa `region`. As peças de `flat` são recortadas só em X e Z,
## depois do recorte das outras.
func _cut_combiner(pieces: Array, region: AABB, cut_material: Material, flat: Dictionary) -> CSGCombiner3D:
	var combiner := CSGCombiner3D.new()
	for piece: CSGShape3D in pieces:
		if not flat.has(piece):
			var copy := piece.duplicate() as CSGShape3D
			copy.transform = _map_transform(piece)
			copy.use_collision = false
			combiner.add_child(copy)
	# Sem peças antes dele, o recorte viraria a própria caixa do bloco.
	if combiner.get_child_count() > 0:
		var box := CSGBox3D.new()
		box.position = region.get_center()
		box.size = region.size
		box.operation = CSGShape3D.OPERATION_INTERSECTION
		box.material = cut_material
		combiner.add_child(box)
	for piece: CSGShape3D in pieces:
		if flat.has(piece):
			var aabb := _piece_bounds(piece)
			var low := Vector3(maxf(aabb.position.x, region.position.x), aabb.position.y,
				maxf(aabb.position.z, region.position.z))
			var high := Vector3(minf(aabb.end.x, region.end.x), aabb.end.y, minf(aabb.end.z, region.end.z))
			if high.x - low.x < 0.001 or high.z - low.z < 0.001:
				continue
			var copy := piece.duplicate() as CSGBox3D
			copy.transform = Transform3D(Basis(), (low + high) * 0.5)
			copy.size = high - low
			copy.use_collision = false
			combiner.add_child(copy)
	root.add_child(combiner)
	return combiner


## Avisa sobre blocos com mais luzes ao alcance do que o Mobile e o Compatibility
## aplicam (as que sobram são escolhidas sem critério de distância).
func _report_lights(baked: Node3D) -> void:
	var lights: Array[Dictionary] = []
	for node in map_root.find_children("*", "Light3D", true, false):
		if node is OmniLight3D:
			lights.append({"at": _map_transform(node).origin, "range": (node as OmniLight3D).omni_range,
				"mask": (node as Light3D).light_cull_mask})
		elif node is SpotLight3D:
			lights.append({"at": _map_transform(node).origin, "range": (node as SpotLight3D).spot_range,
				"mask": (node as Light3D).light_cull_mask})
	var most := 0
	var crowded := 0
	for block: MeshInstance3D in baked.get_children():
		var aabb := block.mesh.get_aabb()
		var count := 0
		for light in lights:
			var at: Vector3 = light.at
			if light.mask & block.layers and at.clamp(aabb.position, aabb.end).distance_to(at) < light.range:
				count += 1
		most = maxi(most, count)
		if count > MAX_LIGHTS_PER_MESH:
			crowded += 1
			print("  bloco com %d luzes ao alcance: %s (%s)" % [count, block.name, aabb.get_center().snapped(Vector3.ONE * 0.1)])
	print("blocos assados: %d | luzes ao alcance de um bloco: até %d | blocos com mais de %d: %d" % [
		baked.get_child_count(), most, MAX_LIGHTS_PER_MESH, crowded])


## Caixa envolvente de uma peça CSG (caixa ou malha) em relação à raiz do mapa.
func _piece_bounds(piece: CSGShape3D) -> AABB:
	var local := AABB()
	if piece is CSGBox3D:
		var size := (piece as CSGBox3D).size
		local = AABB(-size * 0.5, size)
	elif piece is CSGMesh3D:
		local = (piece as CSGMesh3D).mesh.get_aabb()
	return _map_transform(piece) * local


func _chunk_of(point: Vector3) -> Vector3i:
	var level := 0
	for height in chunk_levels:
		if point.y > height:
			level += 1
	return Vector3i(floori((point.x - CHUNK_OFFSET) / CHUNK_SIZE), level,
		floori((point.z - CHUNK_OFFSET) / CHUNK_SIZE))


## Caixa de um bloco; na altura vai de um corte ao outro (ou até `limits`).
func _chunk_bounds(cell: Vector3i, limits: AABB) -> AABB:
	var bottom := limits.position.y if cell.y == 0 else chunk_levels[cell.y - 1]
	var top := limits.end.y if cell.y == chunk_levels.size() else chunk_levels[cell.y]
	var start := Vector3(cell.x * CHUNK_SIZE + CHUNK_OFFSET, bottom, cell.z * CHUNK_SIZE + CHUNK_OFFSET)
	return AABB(start, Vector3(CHUNK_SIZE, top - bottom, CHUNK_SIZE))


## Malha de um bloco. As superfícies de cor lisa (materiais de
## PropBuilder.get_material) viram uma só, com a cor nos vértices e um material
## compartilhado: uma chamada de desenho por bloco em vez de uma por cor.
func _block_mesh(surfaces: Array[Dictionary]) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var plain: Array[Dictionary] = []
	for surface in surfaces:
		var material: Material = surface.material
		if material is StandardMaterial3D and material == PropBuilder.get_material(material.albedo_color):
			var colors := PackedColorArray()
			colors.resize(surface.arrays[Mesh.ARRAY_VERTEX].size())
			colors.fill(material.albedo_color)
			surface.arrays[Mesh.ARRAY_COLOR] = colors
			# Sem textura nem relevo, UV e tangentes só ocupariam espaço.
			surface.arrays[Mesh.ARRAY_TEX_UV] = null
			surface.arrays[Mesh.ARRAY_TANGENT] = null
			plain.append(surface)
		else:
			_add_indexed_surface(mesh, [surface], material)
	if not plain.is_empty():
		if _vertex_color_material == null:
			_vertex_color_material = PropBuilder.get_material(Color.WHITE).duplicate()
			_vertex_color_material.vertex_color_use_as_albedo = true
			_vertex_color_material.vertex_color_is_srgb = true
		_add_indexed_surface(mesh, plain, _vertex_color_material)
	return mesh


## Junta as superfícies (mesmo formato) numa só, indexada.
func _add_indexed_surface(mesh: ArrayMesh, surfaces: Array[Dictionary], material: Material) -> void:
	var tool := SurfaceTool.new()
	for surface in surfaces:
		var part := ArrayMesh.new()
		part.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface.arrays)
		tool.append_from(part, 0, Transform3D.IDENTITY)
	tool.index()
	tool.set_material(material)
	tool.commit(mesh)


func _free_empty_groups(group: Node) -> void:
	for child in group.get_children():
		if child.get_class() == "Node3D":
			_free_empty_groups(child)
	if group.get_child_count() == 0:
		group.free()


## Transformação de um nó em relação à raiz do mapa (que não está na árvore).
func _map_transform(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent != map_root and parent is Node3D:
		result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result


# --- Auxiliares ----------------------------------------------------------------

func _overlap(a: AABB, b: AABB) -> Vector3:
	return a.end.min(b.end) - a.position.max(b.position)


## Pedaços de parede acima (verga) e abaixo (peitoril) de um vão [centro, largura, peitoril, topo].
func _gap_fillers(gap: Array, height: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if gap.size() < 4:
		return result
	if gap[2] > 0.0:
		result.append(Vector2(0.0, gap[2]))
	if gap[3] < height:
		result.append(Vector2(gap[3], height))
	return result


## Partes de `rect` fora de `hole` (até 4 retângulos).
func _subtract_rect(rect: Rect2, hole: Rect2) -> Array[Rect2]:
	var cut := rect.intersection(hole)
	if cut.has_area() == false:
		return [rect]
	var result: Array[Rect2] = []
	if cut.position.y > rect.position.y:
		result.append(Rect2(rect.position.x, rect.position.y, rect.size.x, cut.position.y - rect.position.y))
	if cut.end.y < rect.end.y:
		result.append(Rect2(rect.position.x, cut.end.y, rect.size.x, rect.end.y - cut.end.y))
	if cut.position.x > rect.position.x:
		result.append(Rect2(rect.position.x, cut.position.y, cut.position.x - rect.position.x, cut.size.y))
	if cut.end.x < rect.end.x:
		result.append(Rect2(cut.end.x, cut.position.y, rect.end.x - cut.end.x, cut.size.y))
	return result


func _segments(start: float, end: float, gaps: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var cursor := start
	for gap in gaps:
		# Cada pedaço de parede avança meia espessura além da ponta (para fechar os
		# cantos); o vão compensa isso, então a largura do vão é a largura livre.
		var half: float = gap[1] * 0.5 + WALL_THICKNESS * 0.5
		if gap[0] - half > cursor:
			result.append(Vector2(cursor, gap[0] - half))
		cursor = gap[0] + half
	if end > cursor:
		result.append(Vector2(cursor, end))
	return result


func _marker(marker_name: String, at: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = at
	map_root.add_child(marker)


func _set_owner_recursive(node: Node) -> void:
	for child in node.get_children():
		child.owner = map_root
		# Instâncias de cena (Prop) guardam seus próprios filhos.
		if child.scene_file_path.is_empty():
			_set_owner_recursive(child)
