@tool
class_name Prop
extends StaticBody3D
## Objeto do cenário: uma primitiva (`kind` vazio) ou um objeto composto do
## PropCatalog (mesa, geladeira...). A origem fica na base do objeto.
## Objetos `disguisable` podem ser copiados pelos escondidos; os demais são
## apenas decoração (partes de móveis, por exemplo).

## Objeto do catálogo. Vazio = primitiva definida por `shape`, `size` e `color`.
@export var kind := "":
	set(value):
		kind = value
		_rebuild()
## Cores de cada slot do objeto do catálogo (vazio = cores padrão).
@export var colors := PackedColorArray():
	set(value):
		colors = value
		_rebuild()
@export var shape: PropBuilder.Shape = PropBuilder.Shape.BOX:
	set(value):
		shape = value
		_rebuild()
@export var size := Vector3(0.5, 0.5, 0.5):
	set(value):
		size = value
		_rebuild()
@export var color := Color("b07a4f"):
	set(value):
		color = value
		_rebuild()
## Nome mostrado na mira das primitivas (os objetos do catálogo já têm nome).
@export var label := ""
@export var disguisable := true:
	set(value):
		disguisable = value
		_update_layers()

var _mesh_instance: MeshInstance3D
var _shape_nodes: Array = []


func _ready() -> void:
	_rebuild()
	_update_layers()


func get_disguise() -> Dictionary:
	if kind != "":
		return {"kind": kind, "colors": colors}
	return {"shape": shape, "size": size, "color": color}


## Nome mostrado na mira do escondido.
func get_label() -> String:
	if kind != "":
		return PropCatalog.display_name(kind)
	return label if label != "" else "objeto"


func _validate_property(property: Dictionary) -> void:
	if property.name == "kind":
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(PropCatalog.kinds())
	elif property.name in ["shape", "size", "color", "label"] and kind != "":
		property.usage = PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_STORAGE
	elif property.name == "colors" and kind == "":
		property.usage = PROPERTY_USAGE_NO_EDITOR | PROPERTY_USAGE_STORAGE


func _rebuild() -> void:
	if not is_node_ready():
		return
	if kind != "" and not PropCatalog.has_kind(kind):
		push_warning("Objeto desconhecido no catálogo: " + kind)
		return
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_FRONT)
	var disguise := get_disguise()
	PropBuilder.apply_mesh(_mesh_instance, disguise)
	PropBuilder.apply_shapes(self, _shape_nodes, disguise, true)
	if Engine.is_editor_hint():
		notify_property_list_changed()


func _update_layers() -> void:
	collision_layer = 2 if disguisable else 1
	collision_mask = 0
	if Engine.is_editor_hint() or not is_node_ready():
		return
	if disguisable:
		add_to_group("props")
	elif is_in_group("props"):
		remove_from_group("props")
