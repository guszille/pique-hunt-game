class_name AlienModel
extends Node3D
## Visual do jogador: um alien montado com primitivas, na cor do jogador.
## Cabe na cápsula de colisão (0,7 × 1,7 m); a frente aponta para -Z.
## O procurador usa visor, mochila e scanner; o infectado usa o mesmo
## equipamento em verde. A animação é calculada a partir do deslocamento do
## próprio nó, então funciona igual para o jogador local e para os remotos.

const SEEKER_COLOR := Color("ff3d3d")
const INFECTED_COLOR := Color("7cb342")
const GEAR_COLOR := Color("263238")
const EYE_COLOR := Color("141418")

const BODY_Y := 0.58
const HEAD_Y := 1.2
const SHOULDER := Vector3(0.2, 0.86, 0.0)
const HIP_X := 0.12
const WALK_SPEED_REF := 5.0

static var _meshes := {}
static var _glow_materials := {}

var _body: MeshInstance3D
var _head: Node3D
var _eyes: Array[MeshInstance3D] = []
var _arms: Array[Node3D] = []
var _feet: Array[Node3D] = []
var _antennae: Array[Node3D] = []
var _tips: Array[MeshInstance3D] = []
var _skin: Array[MeshInstance3D] = []
var _dark_skin: Array[MeshInstance3D] = []
var _gear: Array[Node3D] = []
var _glow_parts: Array[MeshInstance3D] = []
var _lens: MeshInstance3D

var _last_position := Vector3.ZERO
var _speed := 0.0
var _airborne := 0.0
var _phase := 0.0
var _time := 0.0
var _next_blink := 2.0
var _base_color := Color.WHITE


func _ready() -> void:
	_build()
	_last_position = global_position
	_next_blink = randf_range(1.5, 4.0)


## Cor do jogador e equipamento do papel atual.
func setup(color: Color, seeker: bool, infected: bool) -> void:
	_base_color = color
	var skin := PropBuilder.get_material(color)
	var dark := PropBuilder.get_material(color.darkened(0.3))
	for part in _skin:
		part.material_override = skin
	for part in _dark_skin:
		part.material_override = dark
	for part in _gear:
		part.visible = seeker or infected
	var glow: Color = INFECTED_COLOR if infected else SEEKER_COLOR if seeker else color.lightened(0.55)
	for tip in _tips:
		tip.material_override = _glow_material(glow)
	for part in _glow_parts:
		part.material_override = _glow_material(INFECTED_COLOR if infected else SEEKER_COLOR)
	_lens.material_override = _glow_material(INFECTED_COLOR if infected else SEEKER_COLOR, 0.45)


## Ignora o deslocamento acumulado (teleporte, volta do disfarce).
func reset_motion() -> void:
	_last_position = global_position
	_speed = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree() or delta <= 0.0:
		_last_position = global_position
		return
	_time += delta
	var moved := global_position - _last_position
	_last_position = global_position
	var horizontal := Vector2(moved.x, moved.z).length() / delta
	if horizontal > 30.0:
		horizontal = 0.0
	_speed = lerpf(_speed, horizontal, minf(1.0, delta * 10.0))
	var vertical := moved.y / delta
	_airborne = lerpf(_airborne, 1.0 if absf(vertical) > 1.5 else 0.0, minf(1.0, delta * 8.0))

	var walk := clampf(_speed / WALK_SPEED_REF, 0.0, 1.4)
	_phase += delta * (2.0 + _speed * 2.2)
	var stride := sin(_phase)
	var bob := absf(cos(_phase)) * 0.05 * walk
	var breath := sin(_time * 2.2) * 0.015 * (1.0 - minf(walk, 1.0))

	_body.position.y = BODY_Y + bob
	_body.scale = Vector3(1.0 + breath, 1.0 - breath, 1.0 + breath)
	_head.position.y = HEAD_Y + bob * 1.2 + breath * 0.5
	_head.rotation.z = sin(_phase * 0.5) * 0.06 * walk
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var swing := stride * side * 0.6 * walk
		# Braços balançam ao andar e sobem no ar.
		_arms[i].rotation.x = swing + _airborne * 2.4
		_arms[i].rotation.z = side * (0.25 + _airborne * 0.5 + breath * 2.0)
		var foot := _feet[i]
		foot.position.z = stride * side * 0.14 * walk
		foot.position.y = maxf(0.0, -cos(_phase) * side) * 0.07 * walk
		_antennae[i].rotation.z = -side * 0.3 + sin(_time * 3.0 + i) * 0.08 + stride * 0.12 * walk
		_antennae[i].rotation.x = -0.15 + _airborne * 0.4 + bob * 2.0

	_next_blink -= delta
	var blink := 1.0
	if _next_blink < 0.0:
		blink = 0.15
		if _next_blink < -0.12:
			_next_blink = randf_range(2.0, 5.0)
	for eye in _eyes:
		eye.scale.y = blink


func _build() -> void:
	_body = _part(self, "sphere_body", Vector3(0, BODY_Y, 0), _skin)

	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var foot := Node3D.new()
		foot.position = Vector3(side * HIP_X, 0, 0)
		add_child(foot)
		_part(foot, "leg", Vector3(0, 0.15, 0), _dark_skin)
		_part(foot, "foot", Vector3(0, 0.05, -0.05), _dark_skin)
		_feet.append(foot)

		var arm := Node3D.new()
		arm.position = Vector3(side * SHOULDER.x, SHOULDER.y, 0)
		add_child(arm)
		_part(arm, "arm", Vector3(0, -0.2, 0), _skin)
		_part(arm, "hand", Vector3(0, -0.42, 0), _dark_skin)
		_arms.append(arm)

	_head = Node3D.new()
	_head.position.y = HEAD_Y
	add_child(_head)
	_part(_head, "head", Vector3.ZERO, _skin)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var eye := MeshInstance3D.new()
		eye.mesh = _mesh("eye")
		eye.material_override = PropBuilder.get_material(EYE_COLOR)
		eye.position = Vector3(side * 0.13, 0.02, -0.27)
		eye.rotation = Vector3(0.1, side * -0.35, side * -0.2)
		_head.add_child(eye)
		var shine := MeshInstance3D.new()
		shine.mesh = _mesh("shine")
		shine.material_override = _glow_material(Color.WHITE)
		shine.position = Vector3(-0.03, 0.04, -0.045)
		eye.add_child(shine)
		_eyes.append(eye)

		var antenna := Node3D.new()
		antenna.position = Vector3(side * 0.1, 0.22, 0)
		_head.add_child(antenna)
		_part(antenna, "stalk", Vector3(0, 0.1, 0), _skin)
		var tip := MeshInstance3D.new()
		tip.mesh = _mesh("tip")
		tip.position = Vector3(0, 0.21, 0)
		antenna.add_child(tip)
		_tips.append(tip)
		_antennae.append(antenna)

	_build_gear()


## Visor, mochila e scanner do procurador.
func _build_gear() -> void:
	var gear_mat := PropBuilder.get_material(GEAR_COLOR)

	var visor := Node3D.new()
	_head.add_child(visor)
	_gear.append(visor)
	var strap := MeshInstance3D.new()
	strap.mesh = _mesh("strap")
	strap.material_override = gear_mat
	strap.position.y = 0.02
	visor.add_child(strap)
	var lens := MeshInstance3D.new()
	lens.mesh = _mesh("lens")
	lens.position = Vector3(0, 0.02, -0.235)
	visor.add_child(lens)
	_lens = lens

	var pack := MeshInstance3D.new()
	pack.mesh = _mesh("pack")
	pack.material_override = gear_mat
	pack.position = Vector3(0, 0.72, 0.26)
	add_child(pack)
	_gear.append(pack)
	var light := MeshInstance3D.new()
	light.mesh = _mesh("pack_light")
	light.position = Vector3(0, 0.12, 0.08)
	pack.add_child(light)
	_glow_parts.append(light)

	var scanner := Node3D.new()
	_arms[1].add_child(scanner)
	_gear.append(scanner)
	scanner.position = Vector3(0, -0.44, -0.08)
	var body := MeshInstance3D.new()
	body.mesh = _mesh("scanner")
	body.material_override = gear_mat
	scanner.add_child(body)
	var beam := MeshInstance3D.new()
	beam.mesh = _mesh("scanner_tip")
	beam.position = Vector3(0, 0, -0.13)
	scanner.add_child(beam)
	_glow_parts.append(beam)


func _part(parent: Node3D, mesh_name: String, at: Vector3, group: Array[MeshInstance3D]) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _mesh(mesh_name)
	node.position = at
	parent.add_child(node)
	group.append(node)
	return node


static func _mesh(mesh_name: String) -> Mesh:
	if _meshes.has(mesh_name):
		return _meshes[mesh_name]
	var mesh: Mesh
	match mesh_name:
		"sphere_body": mesh = _sphere(0.25, 0.82)
		"head": mesh = _sphere(0.33, 0.56)
		"eye": mesh = _sphere(0.095, 0.27, 0.6)
		"shine": mesh = _sphere(0.025, 0.05)
		"tip": mesh = _sphere(0.05, 0.1)
		"hand": mesh = _sphere(0.07, 0.14)
		"foot": mesh = _sphere(0.11, 0.1, 1.5)
		"arm": mesh = _capsule(0.05, 0.42)
		"leg": mesh = _capsule(0.065, 0.3)
		"stalk": mesh = _cylinder(0.015, 0.2)
		"strap": mesh = _cylinder(0.335, 0.13)
		"lens": mesh = _sphere(0.28, 0.32, 0.55)
		"pack":
			var box := BoxMesh.new()
			box.size = Vector3(0.32, 0.36, 0.14)
			mesh = box
		"pack_light": mesh = _sphere(0.04, 0.08)
		"scanner":
			var box := BoxMesh.new()
			box.size = Vector3(0.08, 0.09, 0.22)
			mesh = box
		"scanner_tip": mesh = _sphere(0.04, 0.08)
	_meshes[mesh_name] = mesh
	return mesh


## Elipsoide: `radius` na horizontal, `height` na vertical; `depth` achata em Z.
static func _sphere(radius: float, height: float, depth := 1.0) -> Mesh:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = height
	sphere.radial_segments = PropBuilder.RADIAL_SEGMENTS
	sphere.rings = PropBuilder.RADIAL_SEGMENTS / 2
	if is_equal_approx(depth, 1.0):
		return sphere
	var tool := SurfaceTool.new()
	tool.append_from(sphere, 0, Transform3D(Basis.from_scale(Vector3(1, 1, depth)), Vector3.ZERO))
	return tool.commit()


static func _capsule(radius: float, height: float) -> Mesh:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 12
	capsule.rings = 4
	return capsule


static func _cylinder(radius: float, height: float) -> Mesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = PropBuilder.RADIAL_SEGMENTS
	return cylinder


## Material que brilha; com `alpha` < 1 vira vidro colorido (lente do visor).
static func _glow_material(color: Color, alpha := 1.0) -> StandardMaterial3D:
	var key := Color(color, alpha)
	if _glow_materials.has(key):
		return _glow_materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = key
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.2 if alpha >= 1.0 else 0.5
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_materials[key] = material
	return material
