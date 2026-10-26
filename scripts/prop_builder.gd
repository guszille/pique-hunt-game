class_name PropBuilder
extends RefCounted
## Gera malhas e formas de colisão a partir de primitivas simples e dos objetos
## compostos do PropCatalog. Usado tanto pelos objetos do cenário quanto pelo
## disfarce dos jogadores, garantindo que a cópia fique idêntica ao original.
##
## Um disfarce é um Dictionary em um destes formatos:
## - primitiva: {"shape", "size", "color"}
## - objeto do catálogo: {"kind", "colors"} (`colors` vazio = cores padrão)
##
## Convenção de `size`:
## - BOX / PRISM: largura (x), altura (y), profundidade (z)
## - CYLINDER / CONE / CAPSULE: diâmetro (x), altura (y)
## - SPHERE: diâmetro (x)

enum Shape { BOX, CYLINDER, CONE, SPHERE, CAPSULE, PRISM }

## Lados de cilindros, cones e esferas. Os padrões do Godot (64) pesam demais
## com centenas de objetos compostos de várias peças redondas.
const RADIAL_SEGMENTS := 20

static var _material_cache := {}
static var _mesh_cache := {}
static var _shape_cache := {}
static var _item_mesh_cache := {}
static var _item_shapes_cache := {}
static var _item_bounds_cache := {}


static func height_of(shape: int, size: Vector3) -> float:
	if shape == Shape.SPHERE:
		return size.x
	if shape == Shape.CAPSULE:
		return maxf(size.y, size.x)
	return size.y


## Objetos iguais compartilham a mesma malha (não modifique o resultado).
static func make_mesh(shape: int, size: Vector3, color: Color) -> Mesh:
	var key := "%d|%s|%s" % [shape, size, color.to_html()]
	if not _mesh_cache.has(key):
		_mesh_cache[key] = _build_mesh(shape, size, color)
	return _mesh_cache[key]


## Objetos iguais compartilham a mesma forma de colisão (não modifique o resultado).
static func make_shape(shape: int, size: Vector3) -> Shape3D:
	var key := "%d|%s" % [shape, size]
	if not _shape_cache.has(key):
		_shape_cache[key] = _build_shape(shape, size)
	return _shape_cache[key]


# --- Disfarces (primitiva ou objeto do catálogo) --------------------------------

## Caixa envolvente do disfarce, com a base em y = 0 (sem girar).
static func bounds_of(disguise: Dictionary) -> AABB:
	if disguise.has("kind"):
		return item_bounds(disguise.kind)
	var shape: int = disguise.shape
	var size: Vector3 = disguise.size
	var depth := size.z if shape == Shape.BOX or shape == Shape.PRISM else size.x
	return AABB(Vector3(-size.x * 0.5, 0.0, -depth * 0.5), Vector3(size.x, height_of(shape, size), depth))


## Coloca a malha do disfarce em `target` (a origem de `target` fica na base).
static func apply_mesh(target: MeshInstance3D, disguise: Dictionary) -> void:
	if disguise.has("kind"):
		target.mesh = make_item_mesh(disguise.kind, disguise.get("colors", PackedColorArray()))
		target.position.y = 0.0
	else:
		target.mesh = make_mesh(disguise.shape, disguise.size, disguise.color)
		target.position.y = height_of(disguise.shape, disguise.size) * 0.5


## Formas de colisão do disfarce: [[Shape3D, Transform3D], ...].
static func disguise_shapes(disguise: Dictionary) -> Array:
	if disguise.has("kind"):
		return make_item_shapes(disguise.kind)
	var height := height_of(disguise.shape, disguise.size)
	return [[make_shape(disguise.shape, disguise.size), Transform3D(Basis.IDENTITY, Vector3.UP * height * 0.5)]]


## Ajusta as CollisionShape3D de `body` ao disfarce, criando ou removendo nós.
## `nodes` é a lista de nós já criados e é atualizada no lugar.
static func apply_shapes(body: Node, nodes: Array, disguise: Dictionary, internal := false) -> void:
	var shapes := disguise_shapes(disguise)
	while nodes.size() < shapes.size():
		var node := CollisionShape3D.new()
		body.add_child(node, false, Node.INTERNAL_MODE_FRONT if internal else Node.INTERNAL_MODE_DISABLED)
		nodes.append(node)
	while nodes.size() > shapes.size():
		var extra: Node = nodes.pop_back()
		body.remove_child(extra)
		extra.queue_free()
	for i in shapes.size():
		nodes[i].shape = shapes[i][0]
		nodes[i].transform = shapes[i][1]


# --- Objetos do catálogo -----------------------------------------------------------

## Uma superfície por slot de cor; objetos iguais compartilham a malha.
static func make_item_mesh(kind: String, colors: PackedColorArray) -> Mesh:
	var palette := PropCatalog.palette(kind, colors)
	var key := kind + "|" + ",".join(Array(palette).map(func(c: Color) -> String: return c.to_html()))
	if not _item_mesh_cache.has(key):
		_item_mesh_cache[key] = _build_item_mesh(kind, palette)
	return _item_mesh_cache[key]


static func make_item_shapes(kind: String) -> Array:
	if not _item_shapes_cache.has(kind):
		var collision: Array = PropCatalog.get_item(kind).get("collision", [])
		var shapes := []
		if collision.is_empty():
			var bounds := item_bounds(kind)
			shapes.append([make_shape(Shape.BOX, bounds.size), Transform3D(Basis.IDENTITY, bounds.get_center())])
		for entry: Dictionary in collision:
			shapes.append([make_shape(entry.shape, entry.size), part_transform(entry)])
		_item_shapes_cache[kind] = shapes
	return _item_shapes_cache[kind]


static func item_bounds(kind: String) -> AABB:
	if not _item_bounds_cache.has(kind):
		var bounds := AABB()
		var first := true
		for part: Dictionary in PropCatalog.get_item(kind).get("parts", []):
			var box := part_transform(part) * make_mesh(part.shape, part.size, Color.WHITE).get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		_item_bounds_cache[kind] = bounds
	return _item_bounds_cache[kind]


static func part_transform(part: Dictionary) -> Transform3D:
	var rot: Vector3 = part.get("rot", Vector3.ZERO)
	return Transform3D(Basis.from_euler(rot * (PI / 180.0)), part.at)


static func _build_item_mesh(kind: String, palette: PackedColorArray) -> Mesh:
	var by_slot := {}
	for part: Dictionary in PropCatalog.get_item(kind).get("parts", []):
		by_slot.get_or_add(part.get("slot", 0), []).append(part)
	var mesh := ArrayMesh.new()
	for slot: int in by_slot:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for part: Dictionary in by_slot[slot]:
			tool.append_from(make_mesh(part.shape, part.size, Color.WHITE), 0, part_transform(part))
		tool.set_material(get_material(palette[slot] if slot < palette.size() else Color.MAGENTA))
		tool.commit(mesh)
	return mesh


static func _build_mesh(shape: int, size: Vector3, color: Color) -> Mesh:
	var mesh: PrimitiveMesh
	var radius := size.x * 0.5
	match shape:
		Shape.CYLINDER:
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = radius
			cylinder.bottom_radius = radius
			cylinder.height = size.y
			cylinder.radial_segments = RADIAL_SEGMENTS
			cylinder.rings = 0
			mesh = cylinder
		Shape.CONE:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = radius
			cone.height = size.y
			cone.radial_segments = RADIAL_SEGMENTS
			cone.rings = 0
			mesh = cone
		Shape.SPHERE:
			var sphere := SphereMesh.new()
			sphere.radius = radius
			sphere.height = size.x
			sphere.radial_segments = RADIAL_SEGMENTS
			sphere.rings = RADIAL_SEGMENTS / 2
			mesh = sphere
		Shape.CAPSULE:
			var capsule := CapsuleMesh.new()
			capsule.radius = radius
			capsule.height = height_of(shape, size)
			capsule.radial_segments = RADIAL_SEGMENTS
			capsule.rings = 4
			mesh = capsule
		Shape.PRISM:
			var prism := PrismMesh.new()
			prism.size = size
			mesh = prism
		_:
			var box := BoxMesh.new()
			box.size = size
			mesh = box
	mesh.material = get_material(color)
	return mesh


static func _build_shape(shape: int, size: Vector3) -> Shape3D:
	var radius := size.x * 0.5
	match shape:
		Shape.CYLINDER:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = radius
			cylinder.height = size.y
			return cylinder
		Shape.SPHERE:
			var sphere := SphereShape3D.new()
			sphere.radius = radius
			return sphere
		Shape.CAPSULE:
			var capsule := CapsuleShape3D.new()
			capsule.radius = radius
			capsule.height = height_of(shape, size)
			return capsule
		Shape.CONE, Shape.PRISM:
			return _build_mesh(shape, size, Color.WHITE).create_convex_shape()
		_:
			var box := BoxShape3D.new()
			box.size = size
			return box


static func get_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.85
		_material_cache[key] = material
	return _material_cache[key]
