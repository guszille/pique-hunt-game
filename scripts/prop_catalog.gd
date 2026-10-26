class_name PropCatalog
extends RefCounted
## Catálogo de objetos compostos (mesa, cadeira, geladeira...). Cada objeto é um
## conjunto de primitivas com cores por slot; veja scripts/catalog/catalog_base.gd.
## Os objetos do mapa e o disfarce dos jogadores usam o mesmo catálogo, então a
## cópia fica idêntica ao original.

const LISTS: Array[String] = [
	"res://scripts/catalog/house_items.gd",
	"res://scripts/catalog/factory_items.gd",
	"res://scripts/catalog/park_items.gd",
]

static var _items := {}


static func has_kind(kind: String) -> bool:
	_ensure_loaded()
	return _items.has(kind)


## {"name", "colors", "parts", "collision"}
static func get_item(kind: String) -> Dictionary:
	_ensure_loaded()
	return _items.get(kind, {})


static func kinds() -> PackedStringArray:
	_ensure_loaded()
	var result := PackedStringArray(_items.keys())
	result.sort()
	return result


static func display_name(kind: String) -> String:
	return get_item(kind).get("name", kind)


## Cores finais de cada slot: as cores dadas substituem as padrão, na ordem.
static func palette(kind: String, colors: PackedColorArray) -> PackedColorArray:
	var result: PackedColorArray = get_item(kind).get("colors", PackedColorArray()).duplicate()
	for i in mini(colors.size(), result.size()):
		result[i] = colors[i]
	return result


static func _ensure_loaded() -> void:
	if not _items.is_empty():
		return
	for path in LISTS:
		var list: Dictionary = load(path).items()
		for kind: String in list:
			assert(not _items.has(kind), "Objeto repetido no catálogo: " + kind)
			_items[kind] = list[kind]
