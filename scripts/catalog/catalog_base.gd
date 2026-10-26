extends RefCounted
## Funções usadas pelas listas do catálogo (house_items.gd, factory_items.gd,
## park_items.gd) para descrever objetos compostos.
##
## Convenções:
## - A origem do objeto fica no centro da base (y = 0), como nos objetos do mapa.
## - A frente do objeto aponta para +Z. Com yaw 0, as costas ficam encostadas
##   numa parede que esteja em z menor.
## - Cada peça tem um `slot` de cor; o objeto define a cor padrão de cada slot,
##   e o mapa pode trocar as cores de cada instância.

const BOX := PropBuilder.Shape.BOX
const CYLINDER := PropBuilder.Shape.CYLINDER
const CONE := PropBuilder.Shape.CONE
const SPHERE := PropBuilder.Shape.SPHERE
const CAPSULE := PropBuilder.Shape.CAPSULE
const PRISM := PropBuilder.Shape.PRISM


static func item(display_name: String, colors: Array, parts: Array, collision: Array = []) -> Dictionary:
	return {
		"name": display_name,
		"colors": PackedColorArray(colors.map(func(c) -> Color: return Color(c))),
		"parts": parts,
		"collision": collision,
	}


## Peça com o centro em `at`. `rot` em graus.
static func part(shape: int, size: Vector3, at: Vector3, slot := 0, rot := Vector3.ZERO) -> Dictionary:
	return {"shape": shape, "size": size, "at": at, "slot": slot, "rot": rot}


## Peça apoiada: `base` é o centro da base da peça.
static func on(shape: int, size: Vector3, base: Vector3, slot := 0) -> Dictionary:
	return part(shape, size, base + Vector3.UP * PropBuilder.height_of(shape, size) * 0.5, slot)


## Caixa de colisão com o centro em `at`. Sem caixas, o objeto usa a caixa envolvente.
static func hit(size: Vector3, at: Vector3) -> Dictionary:
	return {"shape": BOX, "size": size, "at": at, "rot": Vector3.ZERO}


## Quatro pernas (caixas) apoiadas no chão, nos cantos de um retângulo `span`.
static func legs(span: Vector2, height: float, thickness := 0.05, slot := 0) -> Array:
	var result := []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			result.append(on(BOX, Vector3(thickness, height, thickness),
				Vector3(sx * span.x * 0.5, 0.0, sz * span.y * 0.5), slot))
	return result


## Colisão das pernas de `legs()`, para deixar vão embaixo de mesas e camas.
static func leg_hits(span: Vector2, height: float, thickness := 0.05) -> Array:
	var result := []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			result.append(hit(Vector3(thickness, height, thickness),
				Vector3(sx * span.x * 0.5, height * 0.5, sz * span.y * 0.5)))
	return result


## Roda (cilindro com eixo em X) com o centro em `at`.
static func wheel(diameter: float, width: float, at: Vector3, slot := 0) -> Dictionary:
	return part(CYLINDER, Vector3(diameter, width, diameter), at, slot, Vector3(0, 0, 90))
