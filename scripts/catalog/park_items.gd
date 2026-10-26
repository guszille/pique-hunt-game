extends "res://scripts/catalog/catalog_base.gd"
## Objetos do Parque. Medidas em metros; a frente aponta para +Z.


static func items() -> Dictionary:
	var d := {}
	d.merge(_furniture())
	d.merge(_food())
	d.merge(_rides())
	d.merge(_games())
	return d


# --- Mobiliário do parque ----------------------------------------------------------

static func _furniture() -> Dictionary:
	var d := {}
	var bench_parts := [
		part(BOX, Vector3(1.6, 0.05, 0.45), Vector3(0, 0.45, 0)),
		part(BOX, Vector3(1.6, 0.35, 0.05), Vector3(0, 0.75, -0.21)),
		on(BOX, Vector3(0.06, 0.45, 0.45), Vector3(-0.72, 0, 0), 1),
		on(BOX, Vector3(0.06, 0.45, 0.45), Vector3(0.72, 0, 0), 1),
		on(BOX, Vector3(0.06, 0.3, 0.06), Vector3(-0.72, 0.45, -0.21), 1),
		on(BOX, Vector3(0.06, 0.3, 0.06), Vector3(0.72, 0.45, -0.21), 1),
	]
	d["banco_praca"] = item("Banco de praça", ["8d6e63", "37474f"], bench_parts, [
		hit(Vector3(1.6, 0.05, 0.45), Vector3(0, 0.45, 0)),
		hit(Vector3(1.6, 0.35, 0.05), Vector3(0, 0.75, -0.21)),
		hit(Vector3(0.06, 0.45, 0.45), Vector3(-0.72, 0.225, 0)),
		hit(Vector3(0.06, 0.45, 0.45), Vector3(0.72, 0.225, 0)),
	])
	d["lixeira_parque"] = item("Lixeira do parque", ["2e7d32", "1b5e20"], [
		on(CYLINDER, Vector3(0.5, 0.8, 0.5), Vector3.ZERO),
		part(SPHERE, Vector3.ONE * 0.52, Vector3(0, 0.8, 0), 1),
		part(CYLINDER, Vector3(0.52, 0.06, 0.52), Vector3(0, 0.6, 0), 1),
	], [hit(Vector3(0.52, 1.06, 0.52), Vector3(0, 0.53, 0))])
	d["mesa_piquenique"] = item("Mesa de piquenique", ["a1887f", "6d4c41"], [
		part(BOX, Vector3(1.8, 0.05, 0.8), Vector3(0, 0.75, 0)),
		part(BOX, Vector3(1.8, 0.05, 0.3), Vector3(0, 0.45, -0.62)),
		part(BOX, Vector3(1.8, 0.05, 0.3), Vector3(0, 0.45, 0.62)),
		part(BOX, Vector3(0.08, 0.06, 1.6), Vector3(-0.7, 0.4, 0), 1),
		part(BOX, Vector3(0.08, 0.06, 1.6), Vector3(0.7, 0.4, 0), 1),
		part(BOX, Vector3(0.08, 0.8, 0.08), Vector3(-0.7, 0.38, -0.25), 1, Vector3(-22, 0, 0)),
		part(BOX, Vector3(0.08, 0.8, 0.08), Vector3(-0.7, 0.38, 0.25), 1, Vector3(22, 0, 0)),
		part(BOX, Vector3(0.08, 0.8, 0.08), Vector3(0.7, 0.38, -0.25), 1, Vector3(-22, 0, 0)),
		part(BOX, Vector3(0.08, 0.8, 0.08), Vector3(0.7, 0.38, 0.25), 1, Vector3(22, 0, 0)),
	], [
		hit(Vector3(1.8, 0.05, 0.8), Vector3(0, 0.75, 0)),
		hit(Vector3(1.8, 0.05, 0.3), Vector3(0, 0.45, -0.62)),
		hit(Vector3(1.8, 0.05, 0.3), Vector3(0, 0.45, 0.62)),
		hit(Vector3(0.1, 0.75, 0.8), Vector3(-0.7, 0.375, 0)),
		hit(Vector3(0.1, 0.75, 0.8), Vector3(0.7, 0.375, 0)),
	])
	d["mesa_guarda_sol"] = item("Mesa com guarda-sol", ["eceff1", "e53935", "90a4ae"], [
		on(CYLINDER, Vector3(1.0, 0.05, 1.0), Vector3(0, 0.72, 0)),
		on(CYLINDER, Vector3(0.5, 0.04, 0.5), Vector3.ZERO, 2),
		on(CYLINDER, Vector3(0.07, 2.3, 0.07), Vector3(0, 0.04, 0), 2),
		on(CONE, Vector3(2.2, 0.55, 2.2), Vector3(0, 2.0, 0), 1),
	], [
		hit(Vector3(1.0, 0.05, 1.0), Vector3(0, 0.745, 0)),
		hit(Vector3(0.12, 2.3, 0.12), Vector3(0, 1.15, 0)),
		hit(Vector3(0.5, 0.04, 0.5), Vector3(0, 0.02, 0)),
		hit(Vector3(2.2, 0.55, 2.2), Vector3(0, 2.275, 0)),
	])
	d["totem_mapa"] = item("Totem com mapa", ["37474f", "fff8e1", "e53935"], [
		on(BOX, Vector3(0.5, 0.1, 0.4), Vector3.ZERO),
		on(BOX, Vector3(0.12, 1.2, 0.12), Vector3(0, 0.1, 0)),
		part(BOX, Vector3(1.0, 0.8, 0.06), Vector3(0, 1.6, 0)),
		part(BOX, Vector3(0.9, 0.7, 0.01), Vector3(0, 1.6, 0.035), 1),
		part(SPHERE, Vector3.ONE * 0.08, Vector3(0.1, 1.55, 0.045), 2),
	])
	d["poste_fila"] = item("Poste de fila", ["b0bec5", "e53935"], [
		on(CYLINDER, Vector3(0.3, 0.04, 0.3), Vector3.ZERO),
		on(CYLINDER, Vector3(0.06, 0.9, 0.06), Vector3(0, 0.04, 0)),
		part(SPHERE, Vector3.ONE * 0.09, Vector3(0, 0.95, 0)),
		part(BOX, Vector3(1.0, 0.06, 0.01), Vector3(0.53, 0.88, 0), 1),
	], [hit(Vector3(0.3, 0.98, 0.3), Vector3(0, 0.49, 0))])
	d["medidor_altura"] = item("Medidor de altura", ["fdd835", "e53935", "fafafa", "6d4c41"], [
		on(BOX, Vector3(0.6, 0.06, 0.4), Vector3.ZERO, 3),
		on(BOX, Vector3(0.45, 1.3, 0.05), Vector3(0, 0.06, 0)),
		part(BOX, Vector3(0.45, 0.06, 0.06), Vector3(0, 0.6, 0), 1),
		part(BOX, Vector3(0.45, 0.06, 0.06), Vector3(0, 0.9, 0), 1),
		part(BOX, Vector3(0.45, 0.06, 0.06), Vector3(0, 1.2, 0), 1),
		part(SPHERE, Vector3.ONE * 0.45, Vector3(0, 1.55, 0), 2),
		part(SPHERE, Vector3.ONE * 0.08, Vector3(-0.08, 1.6, 0.2), 3),
		part(SPHERE, Vector3.ONE * 0.08, Vector3(0.08, 1.6, 0.2), 3),
	])
	d["carrinho_bebe"] = item("Carrinho de bebê", ["1e88e5", "212121", "bbdefb"], [
		on(BOX, Vector3(0.45, 0.35, 0.75), Vector3(0, 0.4, 0)),
		part(SPHERE, Vector3(0.48, 0.48, 0.48), Vector3(0, 0.82, -0.2)),
		on(BOX, Vector3(0.4, 0.05, 0.68), Vector3(0, 0.75, 0.02), 2),
		wheel(0.22, 0.04, Vector3(-0.22, 0.11, -0.28), 1),
		wheel(0.22, 0.04, Vector3(0.22, 0.11, -0.28), 1),
		wheel(0.22, 0.04, Vector3(-0.22, 0.11, 0.28), 1),
		wheel(0.22, 0.04, Vector3(0.22, 0.11, 0.28), 1),
		part(BOX, Vector3(0.03, 0.03, 0.5), Vector3(-0.2, 0.85, 0.55), 1, Vector3(-30, 0, 0)),
		part(BOX, Vector3(0.03, 0.03, 0.5), Vector3(0.2, 0.85, 0.55), 1, Vector3(-30, 0, 0)),
		part(BOX, Vector3(0.43, 0.03, 0.03), Vector3(0, 0.98, 0.76), 1),
	])
	d["caixa_som"] = item("Caixa de som", ["212121", "616161"], [
		on(BOX, Vector3(0.6, 1.2, 0.5), Vector3.ZERO),
		part(CYLINDER, Vector3(0.42, 0.02, 0.42), Vector3(0, 0.4, 0.255), 1, Vector3(90, 0, 0)),
		part(CYLINDER, Vector3(0.2, 0.02, 0.2), Vector3(0, 0.9, 0.255), 1, Vector3(90, 0, 0)),
	])
	d["bateria"] = item("Bateria", ["c62828", "fafafa", "fdd835", "37474f"], [
		part(CYLINDER, Vector3(0.6, 0.4, 0.6), Vector3(0, 0.3, 0.1), 0, Vector3(90, 0, 0)),
		part(CYLINDER, Vector3(0.58, 0.41, 0.58), Vector3(0, 0.3, 0.1), 1, Vector3(90, 0, 0)),
		on(CYLINDER, Vector3(0.35, 0.18, 0.35), Vector3(-0.42, 0.55, 0.25)),
		on(CYLINDER, Vector3(0.3, 0.2, 0.3), Vector3(-0.15, 0.65, -0.05)),
		on(CYLINDER, Vector3(0.3, 0.2, 0.3), Vector3(0.18, 0.65, -0.05)),
		on(CYLINDER, Vector3(0.03, 1.0, 0.03), Vector3(0.5, 0, 0.2), 3),
		on(CYLINDER, Vector3(0.45, 0.01, 0.45), Vector3(0.5, 1.0, 0.2), 2),
		on(CYLINDER, Vector3(0.03, 0.55, 0.03), Vector3(-0.42, 0, 0.25), 3),
		on(CYLINDER, Vector3(0.35, 0.08, 0.35), Vector3(0, 0, -0.55), 3),
	])
	d["urso_gigante"] = item("Urso gigante", ["8d6e63", "efebe9"], [
		on(SPHERE, Vector3.ONE * 0.8, Vector3(0, 0.1, 0)),
		on(SPHERE, Vector3.ONE * 0.6, Vector3(0, 0.86, 0)),
		on(SPHERE, Vector3.ONE * 0.2, Vector3(-0.22, 1.32, 0)),
		on(SPHERE, Vector3.ONE * 0.2, Vector3(0.22, 1.32, 0)),
		on(SPHERE, Vector3.ONE * 0.2, Vector3(0, 1.02, 0.24), 1),
		on(SPHERE, Vector3.ONE * 0.28, Vector3(-0.4, 0.44, 0.1)),
		on(SPHERE, Vector3.ONE * 0.28, Vector3(0.4, 0.44, 0.1)),
		on(SPHERE, Vector3.ONE * 0.3, Vector3(-0.24, 0, 0.28)),
		on(SPHERE, Vector3.ONE * 0.3, Vector3(0.24, 0, 0.28)),
	])
	return d


# --- Comida ----------------------------------------------------------------------------

static func _food() -> Dictionary:
	var d := {}
	d["carrinho_pipoca"] = _cart("Carrinho de pipoca", ["e53935", "fff59d", "fafafa", "212121"],
		[part(BOX, Vector3(1.0, 0.25, 0.6), Vector3(0, 1.15, 0), 1)])
	d["carrinho_algodao"] = _cart("Carrinho de algodão-doce", ["f48fb1", "fce4ec", "fafafa", "212121"], [
		on(CYLINDER, Vector3(0.03, 0.4, 0.03), Vector3(-0.3, 1.0, 0.2), 2),
		part(SPHERE, Vector3.ONE * 0.32, Vector3(-0.3, 1.5, 0.2), 1),
		on(CYLINDER, Vector3(0.03, 0.4, 0.03), Vector3(0.3, 1.0, 0.2), 2),
		part(SPHERE, Vector3.ONE * 0.32, Vector3(0.3, 1.5, 0.2), 1),
	])
	d["carrinho_sorvete"] = item("Carrinho de sorvete", ["4fc3f7", "fafafa", "212121", "f48fb1"], [
		on(BOX, Vector3(1.0, 0.85, 0.65), Vector3(0, 0.15, 0)),
		on(BOX, Vector3(1.02, 0.08, 0.67), Vector3(0, 1.0, 0), 1),
		wheel(0.3, 0.06, Vector3(-0.45, 0.15, 0.15), 2),
		wheel(0.3, 0.06, Vector3(0.45, 0.15, 0.15), 2),
		on(BOX, Vector3(0.06, 0.15, 0.06), Vector3(0, 0, -0.25), 2),
		on(CYLINDER, Vector3(0.04, 1.0, 0.04), Vector3(0, 1.08, 0), 1),
		on(CONE, Vector3(1.4, 0.4, 1.4), Vector3(0, 2.0, 0), 3),
	], [hit(Vector3(1.05, 1.1, 0.7), Vector3(0, 0.55, 0)), hit(Vector3(0.1, 1.0, 0.1), Vector3(0, 1.6, 0)),
		hit(Vector3(1.4, 0.4, 1.4), Vector3(0, 2.2, 0))])
	d["balde_pipoca"] = item("Balde de pipoca gigante", ["e53935", "fafafa", "fff176"], [
		on(CYLINDER, Vector3(0.7, 0.2, 0.7), Vector3.ZERO),
		on(CYLINDER, Vector3(0.72, 0.2, 0.72), Vector3(0, 0.2, 0), 1),
		on(CYLINDER, Vector3(0.74, 0.2, 0.74), Vector3(0, 0.4, 0)),
		on(CYLINDER, Vector3(0.76, 0.2, 0.76), Vector3(0, 0.6, 0), 1),
		part(SPHERE, Vector3.ONE * 0.74, Vector3(0, 0.82, 0), 2),
	])
	return d


static func _cart(display_name: String, colors: Array, extra: Array) -> Dictionary:
	var parts := [
		on(BOX, Vector3(1.4, 0.85, 0.9), Vector3(0, 0.15, 0)),
		on(BOX, Vector3(1.3, 0.6, 0.8), Vector3(0, 1.0, 0), 1),
		on(PRISM, Vector3(1.6, 0.4, 1.1), Vector3(0, 1.6, 0), 2),
		wheel(0.3, 0.06, Vector3(-0.62, 0.15, 0.2), 3),
		wheel(0.3, 0.06, Vector3(0.62, 0.15, 0.2), 3),
		on(BOX, Vector3(0.06, 0.15, 0.06), Vector3(0, 0, -0.35), 3),
	] + extra
	return item(display_name, colors, parts, [hit(Vector3(1.6, 2.0, 1.1), Vector3(0, 1.0, 0))])


# --- Brinquedos ----------------------------------------------------------------------

static func _rides() -> Dictionary:
	var d := {}
	d["xicara"] = item("Xícara maluca", ["f48fb1", "fafafa", "ad1457"], [
		on(CYLINDER, Vector3(2.0, 0.12, 2.0), Vector3.ZERO, 1),
		on(CYLINDER, Vector3(1.0, 0.25, 1.0), Vector3(0, 0.12, 0)),
		on(CYLINDER, Vector3(1.7, 0.75, 1.7), Vector3(0, 0.37, 0)),
		on(CYLINDER, Vector3(1.78, 0.08, 1.78), Vector3(0, 1.12, 0), 1),
		on(CYLINDER, Vector3(1.4, 0.02, 1.4), Vector3(0, 1.19, 0), 2),
		part(BOX, Vector3(0.12, 0.5, 0.4), Vector3(0.95, 0.75, 0), 1),
	])
	d["pedalinho"] = item("Pedalinho de cisne", ["fafafa", "ff9800", "1e88e5", "212121"], [
		on(BOX, Vector3(1.2, 0.5, 2.0), Vector3.ZERO, 2),
		on(BOX, Vector3(1.1, 0.4, 1.4), Vector3(0, 0.5, -0.2)),
		on(BOX, Vector3(1.0, 0.1, 0.5), Vector3(0, 0.5, 0.45), 2),
		part(CYLINDER, Vector3(0.22, 1.0, 0.22), Vector3(0, 1.1, 0.75), 0, Vector3(20, 0, 0)),
		part(SPHERE, Vector3.ONE * 0.36, Vector3(0, 1.62, 0.95)),
		part(CONE, Vector3(0.12, 0.3, 0.12), Vector3(0, 1.58, 1.18), 1, Vector3(90, 0, 0)),
		part(SPHERE, Vector3.ONE * 0.06, Vector3(-0.13, 1.68, 1.04), 3),
		part(SPHERE, Vector3.ONE * 0.06, Vector3(0.13, 1.68, 1.04), 3),
	])
	d["carrinho_bate_bate"] = item("Carrinho de bate-bate", ["e53935", "212121", "eceff1", "fdd835"], [
		on(BOX, Vector3(1.3, 0.3, 0.9), Vector3(0, 0.08, 0)),
		on(BOX, Vector3(1.4, 0.18, 1.0), Vector3(0, 0, 0), 1),
		on(BOX, Vector3(0.5, 0.45, 0.12), Vector3(-0.3, 0.38, -0.3)),
		on(BOX, Vector3(0.4, 0.12, 0.45), Vector3(-0.3, 0.38, 0.02), 1),
		on(CYLINDER, Vector3(0.04, 0.35, 0.04), Vector3(0.2, 0.38, 0), 1),
		part(CYLINDER, Vector3(0.25, 0.03, 0.25), Vector3(0.2, 0.75, 0), 1, Vector3(0, 0, 30)),
		on(CYLINDER, Vector3(0.05, 1.4, 0.05), Vector3(-0.5, 0.38, -0.35), 2),
		part(SPHERE, Vector3.ONE * 0.1, Vector3(-0.5, 1.83, -0.35), 3),
	])
	d["carrinho_montanha"] = item("Carrinho da montanha-russa", ["1e88e5", "fdd835", "212121"], [
		on(BOX, Vector3(1.1, 0.5, 1.6), Vector3(0, 0.12, 0)),
		on(PRISM, Vector3(1.1, 0.4, 0.4), Vector3(0, 0.62, 0.55), 1),
		on(BOX, Vector3(0.9, 0.35, 0.1), Vector3(0, 0.62, -0.1), 1),
		on(BOX, Vector3(0.9, 0.35, 0.1), Vector3(0, 0.62, -0.7), 1),
		wheel(0.18, 0.06, Vector3(-0.5, 0.09, 0.55), 2),
		wheel(0.18, 0.06, Vector3(0.5, 0.09, 0.55), 2),
		wheel(0.18, 0.06, Vector3(-0.5, 0.09, -0.55), 2),
		wheel(0.18, 0.06, Vector3(0.5, 0.09, -0.55), 2),
	])
	d["carrinho_trem"] = item("Carrinho do trem fantasma", ["6a1b9a", "b388ff", "212121"], [
		on(BOX, Vector3(1.0, 0.55, 1.2), Vector3(0, 0.12, 0)),
		on(BOX, Vector3(0.9, 0.35, 0.1), Vector3(0, 0.67, -0.5), 1),
		part(SPHERE, Vector3.ONE * 0.28, Vector3(0, 0.6, 0.65), 1),
		wheel(0.18, 0.06, Vector3(-0.45, 0.09, 0.4), 2),
		wheel(0.18, 0.06, Vector3(0.45, 0.09, 0.4), 2),
		wheel(0.18, 0.06, Vector3(-0.45, 0.09, -0.4), 2),
		wheel(0.18, 0.06, Vector3(0.45, 0.09, -0.4), 2),
	])
	return d


# --- Jogos ------------------------------------------------------------------------------

static func _games() -> Dictionary:
	var d := {}
	d["fliperama"] = item("Máquina de fliperama", ["3949ab", "212121", "40c4ff", "e53935"], [
		on(BOX, Vector3(0.7, 1.8, 0.75), Vector3.ZERO),
		part(BOX, Vector3(0.6, 0.45, 0.04), Vector3(0, 1.35, 0.33), 1, Vector3(-12, 0, 0)),
		part(BOX, Vector3(0.66, 0.18, 0.06), Vector3(0, 1.72, 0.36), 2),
		part(BOX, Vector3(0.7, 0.08, 0.3), Vector3(0, 0.98, 0.45), 1),
		part(SPHERE, Vector3.ONE * 0.06, Vector3(-0.15, 1.05, 0.45), 3),
		part(SPHERE, Vector3.ONE * 0.05, Vector3(0.1, 1.04, 0.45), 2),
		part(SPHERE, Vector3.ONE * 0.05, Vector3(0.2, 1.04, 0.45), 3),
	])
	d["maquina_pelucia"] = item("Máquina de pegar bicho", ["ff4081", "b3e5fc", "fdd835", "8d6e63"], [
		on(BOX, Vector3(0.95, 0.85, 0.95), Vector3.ZERO),
		on(BOX, Vector3(0.9, 0.95, 0.9), Vector3(0, 0.85, 0), 1),
		on(BOX, Vector3(0.95, 0.25, 0.95), Vector3(0, 1.8, 0)),
		part(BOX, Vector3(0.7, 0.12, 0.04), Vector3(0, 1.93, 0.48), 2),
		part(SPHERE, Vector3.ONE * 0.22, Vector3(-0.2, 0.98, 0.15), 3),
		part(SPHERE, Vector3.ONE * 0.22, Vector3(0.2, 0.98, -0.15), 2),
		on(CYLINDER, Vector3(0.02, 0.3, 0.02), Vector3(0.1, 1.5, 0), 2),
		part(BOX, Vector3(0.5, 0.06, 0.2), Vector3(0, 0.8, 0.55)),
	])
	d["air_hockey"] = item("Mesa de air hockey", ["1e88e5", "eceff1", "e53935", "212121"], [
		part(BOX, Vector3(2.0, 0.2, 1.1), Vector3(0, 0.75, 0)),
		part(BOX, Vector3(1.9, 0.01, 1.0), Vector3(0, 0.855, 0), 1),
		on(CYLINDER, Vector3(0.12, 0.04, 0.12), Vector3(-0.7, 0.86, 0), 2),
		on(CYLINDER, Vector3(0.12, 0.04, 0.12), Vector3(0.7, 0.86, 0), 3),
		on(BOX, Vector3(0.08, 0.65, 0.9), Vector3(-0.85, 0, 0), 3),
		on(BOX, Vector3(0.08, 0.65, 0.9), Vector3(0.85, 0, 0), 3),
	], [
		hit(Vector3(2.0, 0.2, 1.1), Vector3(0, 0.75, 0)),
		hit(Vector3(0.08, 0.65, 0.9), Vector3(-0.85, 0.325, 0)),
		hit(Vector3(0.08, 0.65, 0.9), Vector3(0.85, 0.325, 0)),
	])
	return d
