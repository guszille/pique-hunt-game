extends "res://scripts/catalog/catalog_base.gd"
## Objetos da Casa. Medidas em metros; a frente aponta para +Z.


static func items() -> Dictionary:
	var d := {}
	d.merge(_living())
	d.merge(_kitchen())
	d.merge(_bedrooms())
	d.merge(_bathroom())
	d.merge(_storage())
	d.merge(_outdoor())
	return d


# --- Salas e entrada -----------------------------------------------------------

static func _living() -> Dictionary:
	var d := {}
	d["cadeira"] = item("Cadeira", ["8d6e63", "a1887f"], [
		part(BOX, Vector3(0.45, 0.06, 0.45), Vector3(0, 0.45, 0), 1),
		part(BOX, Vector3(0.45, 0.5, 0.05), Vector3(0, 0.73, -0.2)),
	] + legs(Vector2(0.38, 0.38), 0.42, 0.05))
	d["banqueta"] = item("Banqueta", ["455a64", "ef5350"], [
		on(CYLINDER, Vector3(0.36, 0.03, 0.36), Vector3.ZERO),
		on(CYLINDER, Vector3(0.06, 0.62, 0.06), Vector3(0, 0.03, 0)),
		on(CYLINDER, Vector3(0.4, 0.07, 0.4), Vector3(0, 0.62, 0), 1),
	])
	d["mesa_jantar"] = item("Mesa de jantar", ["a1887f"], [
		part(BOX, Vector3(1.8, 0.06, 1.0), Vector3(0, 0.72, 0)),
	] + legs(Vector2(1.64, 0.84), 0.69, 0.07), [
		hit(Vector3(1.8, 0.06, 1.0), Vector3(0, 0.72, 0)),
	] + leg_hits(Vector2(1.64, 0.84), 0.69, 0.07))
	d["mesinha"] = item("Mesinha", ["bcaaa4", "8d6e63"], [
		on(CYLINDER, Vector3(0.5, 0.04, 0.5), Vector3.ZERO, 1),
		on(CYLINDER, Vector3(0.1, 0.66, 0.1), Vector3(0, 0.04, 0), 1),
		on(CYLINDER, Vector3(1.0, 0.05, 1.0), Vector3(0, 0.7, 0)),
	], [
		hit(Vector3(1.0, 0.05, 1.0), Vector3(0, 0.725, 0)),
		hit(Vector3(0.12, 0.7, 0.12), Vector3(0, 0.35, 0)),
		hit(Vector3(0.5, 0.04, 0.5), Vector3(0, 0.02, 0)),
	])
	d["mesa_centro"] = item("Mesa de centro", ["8d6e63"], [
		part(BOX, Vector3(1.2, 0.06, 0.7), Vector3(0, 0.38, 0)),
		part(BOX, Vector3(1.1, 0.03, 0.6), Vector3(0, 0.1, 0)),
	] + legs(Vector2(1.1, 0.6), 0.35, 0.06))
	d["mesa_lateral"] = item("Mesinha lateral", ["6d4c41", "8d6e63"], [
		on(BOX, Vector3(0.5, 0.5, 0.5), Vector3.ZERO),
		on(BOX, Vector3(0.56, 0.04, 0.56), Vector3(0, 0.5, 0), 1),
	])
	d["sofa2"] = _sofa("Sofá de 2 lugares", 1.5, 2)
	d["sofa3"] = _sofa("Sofá de 3 lugares", 2.2, 3)
	d["poltrona"] = item("Poltrona", ["8e24aa", "ba68c8", "4e342e"], [
		on(BOX, Vector3(0.85, 0.25, 0.8), Vector3(0, 0.1, 0)),
		on(BOX, Vector3(0.55, 0.12, 0.6), Vector3(0, 0.35, 0.08), 1),
		on(BOX, Vector3(0.85, 0.5, 0.18), Vector3(0, 0.35, -0.31)),
		on(BOX, Vector3(0.15, 0.3, 0.8), Vector3(-0.35, 0.35, 0)),
		on(BOX, Vector3(0.15, 0.3, 0.8), Vector3(0.35, 0.35, 0)),
	] + legs(Vector2(0.75, 0.7), 0.1, 0.05, 2))
	d["luminaria"] = item("Luminária de chão", ["37474f", "fff59d"], [
		on(CYLINDER, Vector3(0.35, 0.04, 0.35), Vector3.ZERO),
		on(CYLINDER, Vector3(0.04, 1.45, 0.04), Vector3(0, 0.04, 0)),
		on(CYLINDER, Vector3(0.45, 0.35, 0.45), Vector3(0, 1.45, 0), 1),
	])
	d["abajur"] = item("Abajur", ["5d4037", "fff176"], [
		on(CYLINDER, Vector3(0.18, 0.04, 0.18), Vector3.ZERO),
		on(CYLINDER, Vector3(0.04, 0.28, 0.04), Vector3(0, 0.04, 0)),
		on(CYLINDER, Vector3(0.34, 0.25, 0.34), Vector3(0, 0.3, 0), 1),
	])
	d["rack_tv"] = item("Rack com TV", ["6d4c41", "212121"], [
		on(BOX, Vector3(1.8, 0.5, 0.45), Vector3.ZERO),
		on(BOX, Vector3(0.4, 0.05, 0.2), Vector3(0, 0.5, -0.08), 1),
		on(BOX, Vector3(1.4, 0.8, 0.06), Vector3(0, 0.55, -0.08), 1),
	])
	d["estante"] = _bookcase("Estante", Vector3(1.0, 1.9, 0.4), 4)
	d["estante_baixa"] = _bookcase("Estante baixa", Vector3(0.9, 1.1, 0.35), 2)
	d["sapateira"] = item("Sapateira", ["a1887f", "6d4c41"], [
		on(BOX, Vector3(0.8, 0.9, 0.35), Vector3.ZERO),
		part(BOX, Vector3(0.02, 0.8, 0.01), Vector3(0, 0.45, 0.176), 1),
		part(BOX, Vector3(0.03, 0.12, 0.03), Vector3(-0.06, 0.6, 0.19), 1),
		part(BOX, Vector3(0.03, 0.12, 0.03), Vector3(0.06, 0.6, 0.19), 1),
	])
	d["cabideiro"] = item("Cabideiro", ["5d4037", "1565c0", "c62828"], [
		on(CYLINDER, Vector3(0.4, 0.04, 0.4), Vector3.ZERO),
		on(CYLINDER, Vector3(0.05, 1.75, 0.05), Vector3(0, 0.04, 0)),
		on(BOX, Vector3(0.4, 0.75, 0.16), Vector3(0, 0.85, 0.1), 1),
		on(BOX, Vector3(0.35, 0.6, 0.15), Vector3(0.05, 1.0, -0.1), 2),
	], [hit(Vector3(0.45, 1.8, 0.45), Vector3(0, 0.9, 0))])
	d["aparador"] = item("Aparador", ["6d4c41"], [
		part(BOX, Vector3(1.4, 0.05, 0.4), Vector3(0, 0.8, 0)),
		part(BOX, Vector3(1.3, 0.03, 0.34), Vector3(0, 0.2, 0)),
	] + legs(Vector2(1.3, 0.32), 0.78, 0.05), [
		hit(Vector3(1.4, 0.05, 0.4), Vector3(0, 0.8, 0)),
		hit(Vector3(1.35, 0.25, 0.36), Vector3(0, 0.12, 0)),
	])
	d["buffet"] = item("Buffet", ["795548", "a1887f"], [
		on(BOX, Vector3(1.6, 0.85, 0.5), Vector3.ZERO),
		part(BOX, Vector3(0.02, 0.7, 0.01), Vector3(-0.4, 0.42, 0.251), 1),
		part(BOX, Vector3(0.02, 0.7, 0.01), Vector3(0, 0.42, 0.251), 1),
		part(BOX, Vector3(0.02, 0.7, 0.01), Vector3(0.4, 0.42, 0.251), 1),
		on(BOX, Vector3(1.64, 0.04, 0.54), Vector3(0, 0.85, 0), 1),
	])
	d["cristaleira"] = item("Cristaleira", ["6d4c41", "b3e5fc", "a1887f"], [
		on(BOX, Vector3(1.0, 1.9, 0.45), Vector3.ZERO),
		part(BOX, Vector3(0.88, 1.0, 0.01), Vector3(0, 1.35, 0.226), 1),
		part(BOX, Vector3(0.88, 0.02, 0.01), Vector3(0, 1.0, 0.228), 2),
		part(BOX, Vector3(0.02, 0.6, 0.01), Vector3(0, 0.42, 0.226), 2),
	])
	return d


static func _sofa(display_name: String, width: float, seats: int) -> Dictionary:
	var parts := [
		on(BOX, Vector3(width, 0.25, 0.85), Vector3(0, 0.1, 0)),
		on(BOX, Vector3(width, 0.45, 0.18), Vector3(0, 0.35, -0.335)),
		on(BOX, Vector3(0.16, 0.3, 0.85), Vector3(-width * 0.5 + 0.08, 0.35, 0)),
		on(BOX, Vector3(0.16, 0.3, 0.85), Vector3(width * 0.5 - 0.08, 0.35, 0)),
	] + legs(Vector2(width - 0.12, 0.75), 0.1, 0.05, 2)
	var cushion := (width - 0.36) / seats
	for i in seats:
		var x := -width * 0.5 + 0.18 + cushion * (i + 0.5)
		parts.append(on(BOX, Vector3(cushion - 0.03, 0.12, 0.62), Vector3(x, 0.35, 0.08), 1))
	return item(display_name, ["5c6bc0", "7986cb", "3e2723"], parts)


static func _bookcase(display_name: String, size: Vector3, shelves: int) -> Dictionary:
	var parts := [on(BOX, size, Vector3.ZERO)]
	var step := size.y / shelves
	for i in shelves:
		# Fileira de livros saindo um pouco da frente.
		parts.append(part(BOX, Vector3(size.x - 0.12, step * 0.6, size.z), Vector3(0, step * (i + 0.45), 0.012), 1 + i % 2))
	return item(display_name, ["795548", "c62828", "1e88e5"], parts)


# --- Cozinha e lavanderia ----------------------------------------------------------

static func _kitchen() -> Dictionary:
	var d := {}
	d["geladeira"] = item("Geladeira", ["f5f5f5", "9e9e9e"], [
		on(BOX, Vector3(0.7, 1.8, 0.7), Vector3.ZERO),
		part(BOX, Vector3(0.7, 0.02, 0.01), Vector3(0, 1.2, 0.352), 1),
		part(BOX, Vector3(0.03, 0.35, 0.04), Vector3(0.28, 1.45, 0.37), 1),
		part(BOX, Vector3(0.03, 0.45, 0.04), Vector3(0.28, 0.85, 0.37), 1),
	])
	d["fogao"] = item("Fogão", ["eceff1", "212121", "9e9e9e"], [
		on(BOX, Vector3(0.6, 0.85, 0.6), Vector3.ZERO),
		on(BOX, Vector3(0.6, 0.03, 0.6), Vector3(0, 0.85, 0), 1),
		on(CYLINDER, Vector3(0.14, 0.02, 0.14), Vector3(-0.14, 0.88, -0.14), 2),
		on(CYLINDER, Vector3(0.14, 0.02, 0.14), Vector3(0.14, 0.88, -0.14), 2),
		on(CYLINDER, Vector3(0.14, 0.02, 0.14), Vector3(-0.14, 0.88, 0.14), 2),
		on(CYLINDER, Vector3(0.14, 0.02, 0.14), Vector3(0.14, 0.88, 0.14), 2),
		part(BOX, Vector3(0.44, 0.28, 0.01), Vector3(0, 0.42, 0.302), 1),
		on(BOX, Vector3(0.6, 0.15, 0.04), Vector3(0, 0.88, -0.28)),
	])
	d["micro_ondas"] = item("Micro-ondas", ["eceff1", "263238", "90a4ae"], [
		on(BOX, Vector3(0.5, 0.3, 0.38), Vector3.ZERO),
		part(BOX, Vector3(0.3, 0.2, 0.01), Vector3(-0.06, 0.15, 0.192), 1),
		part(BOX, Vector3(0.1, 0.22, 0.01), Vector3(0.18, 0.15, 0.192), 2),
	])
	d["armario"] = item("Armário", ["a1887f", "6d4c41"], [
		on(BOX, Vector3(0.8, 2.1, 0.6), Vector3.ZERO),
		part(BOX, Vector3(0.02, 2.0, 0.01), Vector3(0, 1.05, 0.302), 1),
		part(BOX, Vector3(0.03, 0.25, 0.03), Vector3(-0.06, 1.05, 0.32), 1),
		part(BOX, Vector3(0.03, 0.25, 0.03), Vector3(0.06, 1.05, 0.32), 1),
	])
	d["bancada"] = item("Bancada", ["eceff1", "90a4ae", "8d6e63"], [
		on(BOX, Vector3(1.2, 0.86, 0.6), Vector3.ZERO, 2),
		on(BOX, Vector3(1.22, 0.04, 0.64), Vector3(0, 0.86, 0.02)),
		part(BOX, Vector3(0.02, 0.76, 0.01), Vector3(0, 0.43, 0.302), 1),
	])
	d["pia_cozinha"] = item("Pia da cozinha", ["eceff1", "b0bec5", "8d6e63"], [
		on(BOX, Vector3(1.2, 0.86, 0.6), Vector3.ZERO, 2),
		on(BOX, Vector3(1.22, 0.04, 0.64), Vector3(0, 0.86, 0.02)),
		on(BOX, Vector3(0.6, 0.01, 0.4), Vector3(0, 0.9, 0.02), 1),
		on(CYLINDER, Vector3(0.04, 0.3, 0.04), Vector3(0, 0.9, -0.24), 1),
		part(BOX, Vector3(0.04, 0.04, 0.2), Vector3(0, 1.18, -0.16), 1),
	])
	d["panela"] = item("Panela", ["607d8b", "263238"], [
		on(CYLINDER, Vector3(0.3, 0.17, 0.3), Vector3.ZERO),
		on(CYLINDER, Vector3(0.31, 0.02, 0.31), Vector3(0, 0.17, 0)),
		on(SPHERE, Vector3(0.05, 0.05, 0.05), Vector3(0, 0.18, 0), 1),
		part(BOX, Vector3(0.44, 0.03, 0.04), Vector3(0, 0.14, 0), 1),
	])
	d["lixeira"] = item("Lixeira", ["455a64", "263238"], [
		on(CYLINDER, Vector3(0.35, 0.58, 0.35), Vector3.ZERO),
		on(CYLINDER, Vector3(0.37, 0.04, 0.37), Vector3(0, 0.58, 0), 1),
		part(BOX, Vector3(0.12, 0.03, 0.08), Vector3(0, 0.03, 0.2), 1),
	])
	d["galao"] = item("Galão de água", ["4fc3f7", "1565c0"], [
		on(CYLINDER, Vector3(0.27, 0.36, 0.27), Vector3.ZERO),
		on(CYLINDER, Vector3(0.09, 0.07, 0.09), Vector3(0, 0.36, 0)),
		on(CYLINDER, Vector3(0.1, 0.03, 0.1), Vector3(0, 0.43, 0), 1),
	])
	d["maquina_lavar"] = item("Máquina de lavar", ["fafafa", "90caf9", "b0bec5"], [
		on(BOX, Vector3(0.6, 0.85, 0.6), Vector3.ZERO),
		part(CYLINDER, Vector3(0.38, 0.03, 0.38), Vector3(0, 0.42, 0.305), 1, Vector3(90, 0, 0)),
		part(BOX, Vector3(0.6, 0.1, 0.02), Vector3(0, 0.78, 0.305), 2),
	])
	d["secadora"] = item("Secadora", ["fafafa", "455a64", "b0bec5"], [
		on(BOX, Vector3(0.6, 0.85, 0.6), Vector3.ZERO),
		part(BOX, Vector3(0.4, 0.4, 0.02), Vector3(0, 0.42, 0.305), 1),
		part(BOX, Vector3(0.6, 0.1, 0.02), Vector3(0, 0.78, 0.305), 2),
	])
	d["tanque"] = item("Tanque", ["eceff1", "b0bec5"], [
		on(BOX, Vector3(0.6, 0.12, 0.5), Vector3(0, 0.75, 0)),
		on(BOX, Vector3(0.12, 0.75, 0.12), Vector3(0, 0, -0.1), 1),
		on(CYLINDER, Vector3(0.03, 0.2, 0.03), Vector3(0, 0.87, -0.2), 1),
	], [hit(Vector3(0.6, 0.12, 0.5), Vector3(0, 0.81, 0)), hit(Vector3(0.12, 0.75, 0.12), Vector3(0, 0.375, -0.1))])
	d["cesto_roupa"] = item("Cesto de roupa", ["bcaaa4", "8d6e63"], [
		on(CYLINDER, Vector3(0.45, 0.55, 0.45), Vector3.ZERO),
		on(CYLINDER, Vector3(0.48, 0.04, 0.48), Vector3(0, 0.55, 0), 1),
	])
	d["tabua_passar"] = item("Tábua de passar", ["90a4ae", "e1f5fe"], [
		part(BOX, Vector3(0.03, 0.95, 0.03), Vector3(-0.3, 0.42, 0), 0, Vector3(0, 0, 30)),
		part(BOX, Vector3(0.03, 0.95, 0.03), Vector3(0.3, 0.42, 0), 0, Vector3(0, 0, -30)),
		part(BOX, Vector3(1.2, 0.03, 0.35), Vector3(0, 0.85, 0), 1),
	], [hit(Vector3(1.2, 0.03, 0.35), Vector3(0, 0.85, 0)), hit(Vector3(0.8, 0.8, 0.06), Vector3(0, 0.42, 0))])
	return d


# --- Quartos -------------------------------------------------------------------------

static func _bedrooms() -> Dictionary:
	var d := {}
	d["cama_solteiro"] = _bed("Cama de solteiro", 0.95, ["5d4037", "90caf9", "fafafa"])
	d["cama_casal"] = _bed("Cama de casal", 1.6, ["4e342e", "f8bbd0", "fafafa"])
	d["criado_mudo"] = item("Criado-mudo", ["6d4c41", "8d6e63"], [
		on(BOX, Vector3(0.5, 0.55, 0.45), Vector3.ZERO),
		part(BOX, Vector3(0.42, 0.16, 0.01), Vector3(0, 0.42, 0.226), 1),
		part(BOX, Vector3(0.42, 0.16, 0.01), Vector3(0, 0.2, 0.226), 1),
	])
	d["comoda"] = item("Cômoda", ["8d6e63", "bcaaa4"], [
		on(BOX, Vector3(1.2, 0.9, 0.5), Vector3.ZERO),
		part(BOX, Vector3(1.1, 0.22, 0.01), Vector3(0, 0.17, 0.251), 1),
		part(BOX, Vector3(1.1, 0.22, 0.01), Vector3(0, 0.45, 0.251), 1),
		part(BOX, Vector3(1.1, 0.22, 0.01), Vector3(0, 0.73, 0.251), 1),
		on(BOX, Vector3(1.24, 0.03, 0.54), Vector3(0, 0.9, 0)),
	])
	d["guarda_roupa"] = item("Guarda-roupa", ["8d6e63", "5d4037"], [
		on(BOX, Vector3(1.6, 2.1, 0.6), Vector3.ZERO),
		part(BOX, Vector3(0.02, 1.95, 0.01), Vector3(0, 1.05, 0.302), 1),
		part(BOX, Vector3(0.03, 0.3, 0.03), Vector3(-0.08, 1.1, 0.32), 1),
		part(BOX, Vector3(0.03, 0.3, 0.03), Vector3(0.08, 1.1, 0.32), 1),
		on(BOX, Vector3(1.64, 0.05, 0.64), Vector3(0, 2.1, 0), 1),
	])
	d["penteadeira"] = item("Penteadeira", ["f5f5f5", "b3e5fc"], [
		part(BOX, Vector3(1.0, 0.05, 0.45), Vector3(0, 0.75, 0)),
		on(BOX, Vector3(0.3, 0.73, 0.43), Vector3(-0.35, 0, 0)),
		on(BOX, Vector3(0.3, 0.73, 0.43), Vector3(0.35, 0, 0)),
		on(BOX, Vector3(0.6, 0.7, 0.03), Vector3(0, 0.78, -0.2), 1),
	])
	d["escrivaninha"] = item("Escrivaninha", ["8d6e63", "6d4c41"], [
		part(BOX, Vector3(1.2, 0.04, 0.6), Vector3(0, 0.73, 0)),
		on(BOX, Vector3(0.04, 0.71, 0.58), Vector3(-0.58, 0, 0), 1),
		on(BOX, Vector3(0.4, 0.71, 0.58), Vector3(0.4, 0, 0), 1),
	], [
		hit(Vector3(1.2, 0.04, 0.6), Vector3(0, 0.73, 0)),
		hit(Vector3(0.04, 0.71, 0.58), Vector3(-0.58, 0.355, 0)),
		hit(Vector3(0.4, 0.71, 0.58), Vector3(0.4, 0.355, 0)),
	])
	d["cadeira_escritorio"] = item("Cadeira de escritório", ["37474f", "1e88e5", "212121"], [
		on(CYLINDER, Vector3(0.55, 0.05, 0.55), Vector3.ZERO, 2),
		on(CYLINDER, Vector3(0.06, 0.38, 0.06), Vector3(0, 0.05, 0)),
		on(BOX, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.43, 0), 1),
		on(BOX, Vector3(0.46, 0.55, 0.07), Vector3(0, 0.51, -0.23), 1),
	])
	d["berco"] = _crib()
	d["trocador"] = item("Trocador", ["f5f5f5", "80deea", "ffcc80"], [
		on(BOX, Vector3(0.9, 0.85, 0.5), Vector3.ZERO),
		on(BOX, Vector3(0.86, 0.08, 0.48), Vector3(0, 0.85, 0), 1),
		part(BOX, Vector3(0.8, 0.2, 0.01), Vector3(0, 0.6, 0.251), 2),
		part(BOX, Vector3(0.8, 0.2, 0.01), Vector3(0, 0.3, 0.251), 2),
	])
	d["pufe"] = item("Pufe", ["8e24aa", "ba68c8"], [
		on(CYLINDER, Vector3(0.55, 0.38, 0.55), Vector3.ZERO),
		on(CYLINDER, Vector3(0.5, 0.03, 0.5), Vector3(0, 0.38, 0), 1),
	])
	d["bau"] = item("Baú", ["6d4c41", "4e342e", "ffca28"], [
		on(BOX, Vector3(0.9, 0.42, 0.5), Vector3.ZERO),
		on(BOX, Vector3(0.92, 0.1, 0.52), Vector3(0, 0.42, 0), 1),
		part(BOX, Vector3(0.08, 0.1, 0.02), Vector3(0, 0.4, 0.26), 2),
	])
	d["urso"] = _teddy("Urso de pelúcia", 1.0)
	d["ursinho"] = _teddy("Ursinho", 0.55)
	d["cubo_brinquedo"] = item("Cubo de brinquedo", ["ef5350", "fff176"], [
		on(BOX, Vector3(0.35, 0.35, 0.35), Vector3.ZERO),
		part(BOX, Vector3(0.24, 0.24, 0.01), Vector3(0, 0.175, 0.176), 1),
		part(BOX, Vector3(0.24, 0.01, 0.24), Vector3(0, 0.351, 0), 1),
	])
	d["skate"] = item("Skate", ["ff7043", "fafafa"], [
		part(BOX, Vector3(0.2, 0.02, 0.8), Vector3(0, 0.08, 0)),
		wheel(0.06, 0.18, Vector3(0, 0.03, 0.28), 1),
		wheel(0.06, 0.18, Vector3(0, 0.03, -0.28), 1),
	])
	d["cesto_fraldas"] = item("Cesto de fraldas", ["fff9c4", "fafafa"], [
		on(BOX, Vector3(0.45, 0.3, 0.32), Vector3.ZERO),
		on(BOX, Vector3(0.38, 0.12, 0.26), Vector3(0, 0.3, 0), 1),
	])
	return d


static func _bed(display_name: String, width: float, colors: Array) -> Dictionary:
	var parts := [
		on(BOX, Vector3(width, 0.25, 2.0), Vector3(0, 0.3, 0)),
		on(BOX, Vector3(width - 0.05, 0.18, 1.9), Vector3(0, 0.55, 0.03), 1),
		on(BOX, Vector3(width, 0.95, 0.06), Vector3(0, 0, -0.97)),
	] + legs(Vector2(width - 0.1, 1.85), 0.3, 0.06)
	var pillows := 1 if width < 1.2 else 2
	for i in pillows:
		var x := 0.0 if pillows == 1 else (i - 0.5) * width * 0.5
		parts.append(on(BOX, Vector3(minf(0.6, width * 0.45), 0.1, 0.35), Vector3(x, 0.73, -0.72), 2))
	# Vão de 30 cm embaixo da cama para objetos pequenos.
	return item(display_name, colors, parts, [
		hit(Vector3(width, 0.43, 2.0), Vector3(0, 0.515, 0)),
		hit(Vector3(width, 0.95, 0.06), Vector3(0, 0.475, -0.97)),
	] + leg_hits(Vector2(width - 0.1, 1.85), 0.3, 0.06))


static func _crib() -> Dictionary:
	var parts := [
		on(BOX, Vector3(0.7, 0.1, 1.3), Vector3(0, 0.3, 0)),
		on(BOX, Vector3(0.64, 0.1, 1.24), Vector3(0, 0.4, 0), 1),
		part(BOX, Vector3(0.05, 0.04, 1.3), Vector3(-0.33, 0.98, 0)),
		part(BOX, Vector3(0.05, 0.04, 1.3), Vector3(0.33, 0.98, 0)),
		part(BOX, Vector3(0.7, 0.04, 0.05), Vector3(0, 0.98, -0.63)),
		part(BOX, Vector3(0.7, 0.04, 0.05), Vector3(0, 0.98, 0.63)),
	] + legs(Vector2(0.66, 1.26), 1.0, 0.05)
	for i in 6:
		var z := -0.5 + i * 0.2
		parts.append(part(BOX, Vector3(0.025, 0.56, 0.025), Vector3(-0.33, 0.68, z)))
		parts.append(part(BOX, Vector3(0.025, 0.56, 0.025), Vector3(0.33, 0.68, z)))
	parts.append(on(SPHERE, Vector3(0.18, 0.18, 0.18), Vector3(0.05, 0.5, 0.2), 2))
	return item("Berço", ["fafafa", "b3e5fc", "ffcc80"], parts, [
		hit(Vector3(0.7, 0.2, 1.3), Vector3(0, 0.4, 0)),
		hit(Vector3(0.05, 0.7, 1.3), Vector3(-0.33, 0.65, 0)),
		hit(Vector3(0.05, 0.7, 1.3), Vector3(0.33, 0.65, 0)),
		hit(Vector3(0.7, 0.7, 0.05), Vector3(0, 0.65, -0.63)),
		hit(Vector3(0.7, 0.7, 0.05), Vector3(0, 0.65, 0.63)),
	] + leg_hits(Vector2(0.66, 1.26), 0.3, 0.05))


static func _teddy(display_name: String, s: float) -> Dictionary:
	return item(display_name, ["a1887f", "efebe9"], [
		on(SPHERE, Vector3.ONE * 0.4 * s, Vector3(0, 0.05 * s, 0)),
		on(SPHERE, Vector3.ONE * 0.3 * s, Vector3(0, 0.43 * s, 0)),
		on(SPHERE, Vector3.ONE * 0.1 * s, Vector3(-0.11 * s, 0.66 * s, 0)),
		on(SPHERE, Vector3.ONE * 0.1 * s, Vector3(0.11 * s, 0.66 * s, 0)),
		on(SPHERE, Vector3.ONE * 0.1 * s, Vector3(0, 0.51 * s, 0.12 * s), 1),
		on(SPHERE, Vector3.ONE * 0.14 * s, Vector3(-0.2 * s, 0.22 * s, 0.05 * s)),
		on(SPHERE, Vector3.ONE * 0.14 * s, Vector3(0.2 * s, 0.22 * s, 0.05 * s)),
		on(SPHERE, Vector3.ONE * 0.15 * s, Vector3(-0.12 * s, 0, 0.14 * s)),
		on(SPHERE, Vector3.ONE * 0.15 * s, Vector3(0.12 * s, 0, 0.14 * s)),
	])


# --- Banheiros -------------------------------------------------------------------------

static func _bathroom() -> Dictionary:
	var d := {}
	d["vaso_sanitario"] = item("Vaso sanitário", ["fafafa", "eceff1"], [
		on(CYLINDER, Vector3(0.38, 0.4, 0.38), Vector3(0, 0, 0.06)),
		on(CYLINDER, Vector3(0.42, 0.04, 0.42), Vector3(0, 0.4, 0.06), 1),
		on(BOX, Vector3(0.4, 0.35, 0.18), Vector3(0, 0.42, -0.17)),
	])
	d["pia_gabinete"] = item("Pia com gabinete", ["fafafa", "8d6e63", "b0bec5"], [
		on(BOX, Vector3(0.6, 0.8, 0.45), Vector3.ZERO, 1),
		on(BOX, Vector3(0.64, 0.06, 0.48), Vector3(0, 0.8, 0.01)),
		on(CYLINDER, Vector3(0.04, 0.15, 0.04), Vector3(0, 0.86, -0.17), 2),
		part(BOX, Vector3(0.02, 0.6, 0.01), Vector3(0, 0.4, 0.226), 2),
	])
	d["banheira"] = item("Banheira", ["fafafa", "b3e5fc", "b0bec5"], [
		on(BOX, Vector3(1.7, 0.5, 0.75), Vector3(0, 0.1, 0)),
		on(BOX, Vector3(1.5, 0.02, 0.55), Vector3(0, 0.6, 0), 1),
		on(SPHERE, Vector3.ONE * 0.12, Vector3(-0.75, 0, -0.3), 2),
		on(SPHERE, Vector3.ONE * 0.12, Vector3(0.75, 0, -0.3), 2),
		on(SPHERE, Vector3.ONE * 0.12, Vector3(-0.75, 0, 0.3), 2),
		on(SPHERE, Vector3.ONE * 0.12, Vector3(0.75, 0, 0.3), 2),
	])
	d["balanca"] = item("Balança", ["eceff1", "37474f"], [
		on(BOX, Vector3(0.3, 0.05, 0.3), Vector3.ZERO),
		part(BOX, Vector3(0.1, 0.005, 0.06), Vector3(0, 0.052, 0.08), 1),
	])
	d["patinho"] = item("Patinho de borracha", ["ffeb3b", "ff9800"], [
		on(SPHERE, Vector3(0.22, 0.17, 0.22), Vector3.ZERO),
		on(SPHERE, Vector3.ONE * 0.13, Vector3(0, 0.13, 0.05)),
		part(BOX, Vector3(0.06, 0.02, 0.06), Vector3(0, 0.2, 0.13), 1),
	])
	return d


# --- Garagem, porão e sótão ----------------------------------------------------------------

static func _storage() -> Dictionary:
	var d := {}
	d["caixa_papelao"] = item("Caixa de papelão", ["c8a165", "e0c99a"], [
		on(BOX, Vector3(0.5, 0.4, 0.4), Vector3.ZERO),
		part(BOX, Vector3(0.07, 0.005, 0.402), Vector3(0, 0.4, 0), 1),
	])
	d["mala"] = item("Mala", ["1565c0", "212121"], [
		on(BOX, Vector3(0.45, 0.62, 0.22), Vector3.ZERO),
		on(BOX, Vector3(0.15, 0.03, 0.04), Vector3(0, 0.62, 0), 1),
	])
	d["pneu"] = item("Pneu", ["212121", "9e9e9e"], [
		on(CYLINDER, Vector3(0.62, 0.2, 0.62), Vector3.ZERO),
		on(CYLINDER, Vector3(0.32, 0.01, 0.32), Vector3(0, 0.2, 0), 1),
	])
	d["lata_tinta"] = item("Lata de tinta", ["b0bec5", "1e88e5"], [
		on(CYLINDER, Vector3(0.26, 0.3, 0.26), Vector3.ZERO),
		part(CYLINDER, Vector3(0.262, 0.12, 0.262), Vector3(0, 0.15, 0), 1),
	])
	d["cortador_grama"] = item("Cortador de grama", ["e53935", "212121", "9e9e9e"], [
		on(BOX, Vector3(0.5, 0.22, 0.6), Vector3(0, 0.08, 0)),
		wheel(0.16, 0.05, Vector3(-0.27, 0.08, 0.22), 1),
		wheel(0.16, 0.05, Vector3(0.27, 0.08, 0.22), 1),
		wheel(0.16, 0.05, Vector3(-0.27, 0.08, -0.22), 1),
		wheel(0.16, 0.05, Vector3(0.27, 0.08, -0.22), 1),
		part(BOX, Vector3(0.03, 0.03, 0.72), Vector3(-0.2, 0.63, -0.46), 2, Vector3(64, 0, 0)),
		part(BOX, Vector3(0.03, 0.03, 0.72), Vector3(0.2, 0.63, -0.46), 2, Vector3(64, 0, 0)),
		part(BOX, Vector3(0.43, 0.03, 0.03), Vector3(0, 0.95, -0.62), 2),
	])
	d["carrinho_mao"] = item("Carrinho de mão", ["43a047", "212121", "8d6e63"], [
		on(BOX, Vector3(0.6, 0.25, 0.8), Vector3(0, 0.35, 0.05)),
		wheel(0.3, 0.08, Vector3(0, 0.15, 0.55), 1),
		on(BOX, Vector3(0.04, 0.35, 0.04), Vector3(-0.22, 0, -0.25), 2),
		on(BOX, Vector3(0.04, 0.35, 0.04), Vector3(0.22, 0, -0.25), 2),
		part(BOX, Vector3(0.04, 0.04, 0.6), Vector3(-0.25, 0.5, -0.55), 2),
		part(BOX, Vector3(0.04, 0.04, 0.6), Vector3(0.25, 0.5, -0.55), 2),
	])
	d["escada_abrir"] = item("Escada de abrir", ["9e9e9e", "f57c00"], [
		part(BOX, Vector3(0.45, 1.55, 0.04), Vector3(0, 0.75, 0.2), 0, Vector3(-15, 0, 0)),
		part(BOX, Vector3(0.45, 1.55, 0.04), Vector3(0, 0.75, -0.2), 0, Vector3(15, 0, 0)),
		on(BOX, Vector3(0.4, 0.05, 0.25), Vector3(0, 1.45, 0), 1),
	], [hit(Vector3(0.45, 1.5, 0.75), Vector3(0, 0.75, 0))])
	d["bicicleta"] = item("Bicicleta", ["1e88e5", "212121"], [
		wheel(0.65, 0.04, Vector3(0, 0.33, 0.52), 1),
		wheel(0.65, 0.04, Vector3(0, 0.33, -0.52), 1),
		part(BOX, Vector3(0.04, 0.04, 0.8), Vector3(0, 0.62, 0)),
		part(BOX, Vector3(0.04, 0.45, 0.04), Vector3(0, 0.5, -0.2), 0, Vector3(-15, 0, 0)),
		part(BOX, Vector3(0.04, 0.5, 0.04), Vector3(0, 0.6, 0.45), 0, Vector3(15, 0, 0)),
		part(BOX, Vector3(0.5, 0.03, 0.03), Vector3(0, 0.9, 0.5), 1),
		part(BOX, Vector3(0.12, 0.05, 0.22), Vector3(0, 0.78, -0.25), 1),
	])
	d["freezer"] = item("Freezer", ["fafafa", "b0bec5"], [
		on(BOX, Vector3(1.2, 0.85, 0.65), Vector3.ZERO),
		part(BOX, Vector3(1.2, 0.02, 0.01), Vector3(0, 0.75, 0.327), 1),
		part(BOX, Vector3(0.3, 0.04, 0.04), Vector3(0, 0.7, 0.35), 1),
	])
	d["barril_pequeno"] = item("Barril", ["8d6e63", "455a64"], [
		on(CYLINDER, Vector3(0.45, 0.6, 0.45), Vector3.ZERO),
		part(CYLINDER, Vector3(0.47, 0.04, 0.47), Vector3(0, 0.12, 0), 1),
		part(CYLINDER, Vector3(0.47, 0.04, 0.47), Vector3(0, 0.48, 0), 1),
	])
	d["bicicleta_ergometrica"] = item("Bicicleta ergométrica", ["37474f", "e53935"], [
		on(BOX, Vector3(0.5, 0.06, 0.9), Vector3.ZERO),
		on(BOX, Vector3(0.12, 0.4, 0.5), Vector3(0, 0.06, 0.15), 1),
		on(BOX, Vector3(0.06, 0.6, 0.06), Vector3(0, 0.06, -0.25)),
		on(BOX, Vector3(0.25, 0.06, 0.3), Vector3(0, 0.66, -0.25), 1),
		on(BOX, Vector3(0.06, 0.7, 0.06), Vector3(0, 0.46, 0.35)),
		part(BOX, Vector3(0.45, 0.04, 0.04), Vector3(0, 1.17, 0.35)),
	])
	d["cadeira_balanco"] = item("Cadeira de balanço", ["6d4c41", "c62828"], [
		part(BOX, Vector3(0.05, 0.06, 0.85), Vector3(-0.22, 0.03, 0)),
		part(BOX, Vector3(0.05, 0.06, 0.85), Vector3(0.22, 0.03, 0)),
		on(BOX, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.42, 0), 1),
		part(BOX, Vector3(0.5, 0.65, 0.05), Vector3(0, 0.78, -0.28), 0, Vector3(-12, 0, 0)),
	] + legs(Vector2(0.44, 0.4), 0.42, 0.05))
	d["cavalinho"] = item("Cavalinho de balanço", ["fafafa", "e53935", "6d4c41"], [
		part(BOX, Vector3(0.05, 0.06, 0.9), Vector3(-0.15, 0.03, 0), 1),
		part(BOX, Vector3(0.05, 0.06, 0.9), Vector3(0.15, 0.03, 0), 1),
		part(BOX, Vector3(0.25, 0.25, 0.6), Vector3(0, 0.48, 0)),
		part(BOX, Vector3(0.18, 0.32, 0.22), Vector3(0, 0.72, 0.3), 0, Vector3(-20, 0, 0)),
		part(BOX, Vector3(0.05, 0.28, 0.15), Vector3(0, 0.78, 0.22), 2, Vector3(-20, 0, 0)),
	] + legs(Vector2(0.2, 0.42), 0.36, 0.05, 2))
	d["manequim"] = item("Manequim", ["5d4037", "f5f5f5"], [
		on(CYLINDER, Vector3(0.32, 0.03, 0.32), Vector3.ZERO),
		on(CYLINDER, Vector3(0.03, 0.6, 0.03), Vector3(0, 0.03, 0)),
		on(CAPSULE, Vector3(0.36, 0.7, 0.36), Vector3(0, 0.6, 0), 1),
		on(CYLINDER, Vector3(0.06, 0.12, 0.06), Vector3(0, 1.28, 0), 1),
	])
	d["movel_coberto"] = _sheet("Móvel coberto", Vector3(1.0, 0.9, 0.75))
	d["movel_coberto_alto"] = _sheet("Armário coberto", Vector3(0.9, 1.6, 0.5))
	d["quadro_coberto"] = item("Quadro coberto", ["f5f5f5", "8d6e63"], [
		part(BOX, Vector3(0.9, 1.2, 0.06), Vector3(0, 0.6, 0), 0, Vector3(-10, 0, 0)),
		part(BOX, Vector3(0.9, 0.06, 0.12), Vector3(0, 0.03, 0.08), 1),
	])
	d["rolo_tapete"] = item("Rolo de tapete", ["c62828", "ffca28"], [
		part(CYLINDER, Vector3(0.3, 1.8, 0.3), Vector3(0, 0.15, 0), 0, Vector3(0, 0, 90)),
		part(CYLINDER, Vector3(0.12, 1.81, 0.12), Vector3(0, 0.15, 0), 1, Vector3(0, 0, 90)),
	])
	d["caixa_natal"] = item("Caixa de enfeites", ["c62828", "2e7d32"], [
		on(BOX, Vector3(0.6, 0.4, 0.45), Vector3.ZERO),
		on(BOX, Vector3(0.62, 0.08, 0.47), Vector3(0, 0.4, 0), 1),
	])
	d["pote_conserva"] = item("Pote de conserva", ["c5e1a5", "fbc02d"], [
		on(CYLINDER, Vector3(0.16, 0.22, 0.16), Vector3.ZERO),
		on(CYLINDER, Vector3(0.17, 0.03, 0.17), Vector3(0, 0.22, 0), 1),
	])
	d["prateleira_metal"] = _metal_shelf()
	d["mesa_sinuca"] = item("Mesa de sinuca", ["4e342e", "2e7d32"], [
		on(BOX, Vector3(2.4, 0.15, 1.3), Vector3(0, 0.62, 0)),
		on(BOX, Vector3(2.2, 0.02, 1.1), Vector3(0, 0.77, 0), 1),
		on(BOX, Vector3(2.4, 0.06, 0.1), Vector3(0, 0.77, -0.6)),
		on(BOX, Vector3(2.4, 0.06, 0.1), Vector3(0, 0.77, 0.6)),
		on(BOX, Vector3(0.1, 0.06, 1.1), Vector3(-1.15, 0.77, 0)),
		on(BOX, Vector3(0.1, 0.06, 1.1), Vector3(1.15, 0.77, 0)),
	] + legs(Vector2(2.1, 1.0), 0.62, 0.12), [
		hit(Vector3(2.4, 0.21, 1.3), Vector3(0, 0.725, 0)),
	] + leg_hits(Vector2(2.1, 1.0), 0.62, 0.12))
	d["caldeira"] = item("Caldeira", ["b0bec5", "8d6e63", "e65100"], [
		on(CYLINDER, Vector3(0.8, 1.7, 0.8), Vector3.ZERO),
		on(CYLINDER, Vector3(0.82, 0.05, 0.82), Vector3(0, 1.2, 0), 1),
		on(CYLINDER, Vector3(0.12, 0.9, 0.12), Vector3(0.2, 1.7, -0.1), 1),
		part(BOX, Vector3(0.25, 0.15, 0.02), Vector3(0, 0.6, 0.405), 2),
	])
	return d


static func _metal_shelf() -> Dictionary:
	var parts := legs(Vector2(0.95, 0.4), 1.8, 0.04)
	var collision := leg_hits(Vector2(0.95, 0.4), 1.8, 0.04)
	for y in [0.15, 0.7, 1.25, 1.78]:
		parts.append(part(BOX, Vector3(1.0, 0.03, 0.45), Vector3(0, y, 0), 1))
		collision.append(hit(Vector3(1.0, 0.03, 0.45), Vector3(0, y, 0)))
	# Caixas e latas guardadas, para a prateleira não parecer vazia.
	parts.append(on(BOX, Vector3(0.4, 0.3, 0.35), Vector3(-0.2, 0.165, 0), 2))
	parts.append(on(BOX, Vector3(0.3, 0.25, 0.3), Vector3(0.25, 0.715, 0), 2))
	parts.append(on(CYLINDER, Vector3(0.2, 0.25, 0.2), Vector3(-0.25, 1.265, 0), 3))
	parts.append(on(CYLINDER, Vector3(0.2, 0.25, 0.2), Vector3(0.0, 1.265, 0), 3))
	return item("Prateleira de metal", ["78909c", "b0bec5", "c8a165", "1e88e5"], parts, collision)


static func _sheet(display_name: String, size: Vector3) -> Dictionary:
	return item(display_name, ["f5f5f5", "e0e0e0"], [
		on(BOX, Vector3(size.x + 0.06, 0.15, size.z + 0.06), Vector3.ZERO, 1),
		on(BOX, size - Vector3(0, 0.15, 0), Vector3(0, 0.15, 0)),
		on(BOX, Vector3(size.x - 0.1, 0.06, size.z - 0.1), Vector3(0, size.y, 0), 1),
	])


# --- Quintal ----------------------------------------------------------------------------

static func _outdoor() -> Dictionary:
	var d := {}
	d["cadeira_plastica"] = item("Cadeira plástica", ["fafafa"], [
		part(BOX, Vector3(0.45, 0.05, 0.45), Vector3(0, 0.43, 0)),
		part(BOX, Vector3(0.45, 0.4, 0.04), Vector3(0, 0.66, -0.22), 0, Vector3(-8, 0, 0)),
	] + legs(Vector2(0.4, 0.4), 0.42, 0.04))
	d["mesa_jardim"] = item("Mesa de jardim", ["fafafa"], [
		on(CYLINDER, Vector3(0.9, 0.04, 0.9), Vector3(0, 0.68, 0)),
	] + legs(Vector2(0.5, 0.5), 0.68, 0.04), [
		hit(Vector3(0.9, 0.04, 0.9), Vector3(0, 0.7, 0)),
	] + leg_hits(Vector2(0.5, 0.5), 0.68, 0.04))
	d["anao_jardim"] = item("Anão de jardim", ["1e88e5", "ffccbc", "e53935"], [
		on(CONE, Vector3(0.3, 0.35, 0.3), Vector3.ZERO),
		on(SPHERE, Vector3.ONE * 0.18, Vector3(0, 0.32, 0), 1),
		on(CONE, Vector3(0.18, 0.25, 0.18), Vector3(0, 0.46, 0), 2),
		on(CONE, Vector3(0.12, 0.14, 0.12), Vector3(0, 0.26, 0.05), 1),
	])
	d["casinha_cachorro"] = item("Casinha de cachorro", ["d7a86e", "8d3a2a", "212121"], [
		on(BOX, Vector3(0.9, 0.7, 1.0), Vector3.ZERO),
		on(PRISM, Vector3(1.05, 0.4, 1.1), Vector3(0, 0.7, 0), 1),
		part(BOX, Vector3(0.36, 0.45, 0.01), Vector3(0, 0.225, 0.502), 2),
	])
	d["churrasqueira"] = item("Churrasqueira", ["212121", "9e9e9e"], [
		on(SPHERE, Vector3(0.6, 0.6, 0.6), Vector3(0, 0.5, 0)),
		on(CYLINDER, Vector3(0.62, 0.02, 0.62), Vector3(0, 0.79, 0), 1),
		on(SPHERE, Vector3.ONE * 0.06, Vector3(0, 1.08, 0), 1),
		on(CYLINDER, Vector3(0.04, 0.6, 0.04), Vector3(0.2, 0, 0.12), 1),
		on(CYLINDER, Vector3(0.04, 0.6, 0.04), Vector3(-0.2, 0, 0.12), 1),
		on(CYLINDER, Vector3(0.04, 0.6, 0.04), Vector3(0, 0, -0.23), 1),
	], [hit(Vector3(0.62, 1.1, 0.62), Vector3(0, 0.55, 0))])
	d["vaso_planta"] = item("Vaso de planta", ["d84315", "43a047"], [
		on(CYLINDER, Vector3(0.4, 0.38, 0.4), Vector3.ZERO),
		on(SPHERE, Vector3.ONE * 0.6, Vector3(0, 0.3, 0), 1),
	])
	d["vaso_planta_alto"] = item("Planta alta", ["eceff1", "2e7d32"], [
		on(CYLINDER, Vector3(0.38, 0.45, 0.38), Vector3.ZERO),
		on(CONE, Vector3(0.6, 1.1, 0.6), Vector3(0, 0.4, 0), 1),
	])
	d["guarda_sol"] = item("Guarda-sol", ["ffffff", "ef5350"], [
		on(CYLINDER, Vector3(0.45, 0.06, 0.45), Vector3.ZERO),
		on(CYLINDER, Vector3(0.05, 2.1, 0.05), Vector3(0, 0.06, 0)),
		on(CONE, Vector3(2.2, 0.45, 2.2), Vector3(0, 1.9, 0), 1),
	], [hit(Vector3(0.1, 2.1, 0.1), Vector3(0, 1.05, 0)), hit(Vector3(2.2, 0.45, 2.2), Vector3(0, 2.12, 0))])
	d["carro"] = item("Carro", ["1565c0", "263238", "212121"], [
		on(BOX, Vector3(1.8, 0.65, 4.2), Vector3(0, 0.22, 0)),
		on(BOX, Vector3(1.6, 0.55, 2.2), Vector3(0, 0.87, -0.2), 1),
		wheel(0.66, 0.25, Vector3(-0.82, 0.33, 1.35), 2),
		wheel(0.66, 0.25, Vector3(0.82, 0.33, 1.35), 2),
		wheel(0.66, 0.25, Vector3(-0.82, 0.33, -1.35), 2),
		wheel(0.66, 0.25, Vector3(0.82, 0.33, -1.35), 2),
	], [hit(Vector3(1.8, 0.85, 4.2), Vector3(0, 0.45, 0)), hit(Vector3(1.6, 0.55, 2.2), Vector3(0, 1.15, -0.2))])
	return d
