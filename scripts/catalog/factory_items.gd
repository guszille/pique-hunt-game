extends "res://scripts/catalog/catalog_base.gd"
## Objetos da Fábrica. Medidas em metros; a frente aponta para +Z.


static func items() -> Dictionary:
	var d := {}
	d.merge(_cargo())
	d.merge(_drums())
	d.merge(_tools())
	d.merge(_office())
	return d


# --- Carga ---------------------------------------------------------------------

static func _cargo() -> Dictionary:
	var d := {}
	d["pallet"] = _pallet("Pallet", [])
	d["pallet_caixas"] = _pallet("Pallet com caixas", [
		on(BOX, Vector3(0.55, 0.5, 0.45), Vector3(-0.29, 0.15, -0.24), 1),
		on(BOX, Vector3(0.55, 0.5, 0.45), Vector3(0.29, 0.15, -0.24), 1),
		on(BOX, Vector3(0.55, 0.5, 0.45), Vector3(-0.29, 0.15, 0.24), 1),
		on(BOX, Vector3(0.55, 0.5, 0.45), Vector3(0.29, 0.15, 0.24), 1),
		on(BOX, Vector3(0.55, 0.45, 0.45), Vector3(-0.29, 0.65, 0.0), 1),
		part(BOX, Vector3(1.16, 0.01, 0.06), Vector3(0, 0.66, 0), 2),
	])
	d["caixa_madeira"] = _crate("Caixa de madeira", 0.6)
	d["caixote"] = _crate("Caixote", 1.0)
	d["paleteira"] = item("Paleteira", ["e53935", "212121"], [
		part(BOX, Vector3(0.16, 0.07, 1.15), Vector3(-0.25, 0.08, 0.2)),
		part(BOX, Vector3(0.16, 0.07, 1.15), Vector3(0.25, 0.08, 0.2)),
		on(BOX, Vector3(0.66, 0.35, 0.25), Vector3(0, 0.05, -0.5)),
		part(BOX, Vector3(0.05, 0.9, 0.05), Vector3(0, 0.75, -0.6), 1, Vector3(-15, 0, 0)),
		part(BOX, Vector3(0.3, 0.05, 0.05), Vector3(0, 1.2, -0.72), 1),
		wheel(0.16, 0.12, Vector3(0, 0.08, -0.5), 1),
	])
	d["carrinho_carga"] = item("Carrinho de carga", ["1565c0", "212121"], [
		part(BOX, Vector3(0.04, 1.25, 0.04), Vector3(-0.2, 0.68, -0.1)),
		part(BOX, Vector3(0.04, 1.25, 0.04), Vector3(0.2, 0.68, -0.1)),
		part(BOX, Vector3(0.44, 0.04, 0.04), Vector3(0, 1.3, -0.1)),
		part(BOX, Vector3(0.44, 0.04, 0.04), Vector3(0, 0.7, -0.1)),
		on(BOX, Vector3(0.44, 0.03, 0.28), Vector3(0, 0.02, 0.06)),
		wheel(0.22, 0.07, Vector3(-0.27, 0.11, -0.15), 1),
		wheel(0.22, 0.07, Vector3(0.27, 0.11, -0.15), 1),
	])
	d["saco_cimento"] = item("Sacos de cimento", ["d7ccc8", "8d6e63"], [
		on(BOX, Vector3(0.65, 0.14, 0.42), Vector3.ZERO),
		on(BOX, Vector3(0.65, 0.14, 0.42), Vector3(0.02, 0.14, 0.01)),
		on(BOX, Vector3(0.65, 0.14, 0.42), Vector3(-0.01, 0.28, -0.01)),
		part(BOX, Vector3(0.3, 0.005, 0.2), Vector3(-0.01, 0.422, -0.01), 1),
	])
	d["caixa_isopor"] = item("Caixa de isopor", ["fafafa", "90caf9"], [
		on(BOX, Vector3(0.6, 0.38, 0.4), Vector3.ZERO),
		on(BOX, Vector3(0.62, 0.06, 0.42), Vector3(0, 0.38, 0)),
		part(BOX, Vector3(0.3, 0.1, 0.005), Vector3(0, 0.2, 0.202), 1),
	])
	return d


static func _pallet(display_name: String, load: Array) -> Dictionary:
	var parts := [
		on(BOX, Vector3(1.2, 0.03, 0.15), Vector3(0, 0.12, -0.42)),
		on(BOX, Vector3(1.2, 0.03, 0.15), Vector3(0, 0.12, -0.14)),
		on(BOX, Vector3(1.2, 0.03, 0.15), Vector3(0, 0.12, 0.14)),
		on(BOX, Vector3(1.2, 0.03, 0.15), Vector3(0, 0.12, 0.42)),
		on(BOX, Vector3(0.12, 0.12, 1.0), Vector3(-0.54, 0, 0)),
		on(BOX, Vector3(0.12, 0.12, 1.0), Vector3(0, 0, 0)),
		on(BOX, Vector3(0.12, 0.12, 1.0), Vector3(0.54, 0, 0)),
	]
	return item(display_name, ["a1887f", "c8a165", "fafafa"], parts + load)


static func _crate(display_name: String, s: float) -> Dictionary:
	var parts := [on(BOX, Vector3.ONE * s, Vector3.ZERO)]
	# Ripas nas faces da frente e de trás e nas laterais.
	for y in [0.2, 0.8]:
		parts.append(part(BOX, Vector3(s + 0.01, s * 0.12, s + 0.01), Vector3(0, s * y, 0), 1))
	parts.append(part(BOX, Vector3(s * 0.1, s + 0.01, s + 0.01), Vector3(-s * 0.45, s * 0.5, 0), 1))
	parts.append(part(BOX, Vector3(s * 0.1, s + 0.01, s + 0.01), Vector3(s * 0.45, s * 0.5, 0), 1))
	return item(display_name, ["c8a165", "a1887f"], parts)


# --- Tambores e cilindros ------------------------------------------------------------

static func _drums() -> Dictionary:
	var d := {}
	d["tambor"] = item("Tambor", ["1565c0", "0d47a1", "eceff1"], [
		on(CYLINDER, Vector3(0.58, 0.88, 0.58), Vector3.ZERO),
		part(CYLINDER, Vector3(0.6, 0.04, 0.6), Vector3(0, 0.3, 0), 1),
		part(CYLINDER, Vector3(0.6, 0.04, 0.6), Vector3(0, 0.6, 0), 1),
		on(CYLINDER, Vector3(0.08, 0.02, 0.08), Vector3(0.16, 0.88, 0), 2),
	])
	d["tambor_deitado"] = item("Tambor deitado", ["c62828", "8e0000", "6d4c41"], [
		part(CYLINDER, Vector3(0.58, 0.88, 0.58), Vector3(0, 0.33, 0), 0, Vector3(0, 0, 90)),
		part(CYLINDER, Vector3(0.6, 0.04, 0.6), Vector3(-0.15, 0.33, 0), 1, Vector3(0, 0, 90)),
		part(CYLINDER, Vector3(0.6, 0.04, 0.6), Vector3(0.15, 0.33, 0), 1, Vector3(0, 0, 90)),
		on(BOX, Vector3(0.12, 0.08, 0.6), Vector3(-0.3, 0, 0), 2),
		on(BOX, Vector3(0.12, 0.08, 0.6), Vector3(0.3, 0, 0), 2),
	])
	d["bobina"] = item("Bobina de cabo", ["a1887f", "424242"], [
		wheel(1.0, 0.07, Vector3(-0.36, 0.5, 0)),
		wheel(1.0, 0.07, Vector3(0.36, 0.5, 0)),
		wheel(0.72, 0.66, Vector3(0, 0.5, 0), 1),
	])
	d["cilindro_gas"] = item("Cilindro de gás", ["2e7d32", "9e9e9e"], [
		on(CAPSULE, Vector3(0.28, 1.2, 0.28), Vector3.ZERO),
		on(CYLINDER, Vector3(0.08, 0.1, 0.08), Vector3(0, 1.2, 0), 1),
		part(BOX, Vector3(0.16, 0.03, 0.03), Vector3(0, 1.27, 0), 1),
	])
	d["galao_quimico"] = item("Bombona", ["fbc02d", "212121"], [
		on(BOX, Vector3(0.32, 0.45, 0.25), Vector3.ZERO),
		on(CYLINDER, Vector3(0.1, 0.06, 0.1), Vector3(0.08, 0.45, 0), 1),
		on(BOX, Vector3(0.04, 0.06, 0.14), Vector3(-0.08, 0.45, 0)),
	])
	return d


# --- Ferramentas e equipamentos ---------------------------------------------------

static func _tools() -> Dictionary:
	var d := {}
	d["caixa_ferramentas"] = item("Caixa de ferramentas", ["d32f2f", "212121"], [
		on(BOX, Vector3(0.6, 0.28, 0.3), Vector3.ZERO),
		on(BOX, Vector3(0.62, 0.04, 0.32), Vector3(0, 0.28, 0), 1),
		on(BOX, Vector3(0.3, 0.08, 0.03), Vector3(0, 0.32, 0), 1),
	])
	d["armario_ferramentas"] = item("Armário de ferramentas", ["d32f2f", "b0bec5", "212121"], [
		on(BOX, Vector3(0.75, 0.9, 0.5), Vector3(0, 0.1, 0)),
		part(BOX, Vector3(0.68, 0.14, 0.01), Vector3(0, 0.3, 0.252), 1),
		part(BOX, Vector3(0.68, 0.14, 0.01), Vector3(0, 0.5, 0.252), 1),
		part(BOX, Vector3(0.68, 0.14, 0.01), Vector3(0, 0.7, 0.252), 1),
		part(BOX, Vector3(0.68, 0.14, 0.01), Vector3(0, 0.88, 0.252), 1),
		on(SPHERE, Vector3.ONE * 0.1, Vector3(-0.3, 0, -0.18), 2),
		on(SPHERE, Vector3.ONE * 0.1, Vector3(0.3, 0, -0.18), 2),
		on(SPHERE, Vector3.ONE * 0.1, Vector3(-0.3, 0, 0.18), 2),
		on(SPHERE, Vector3.ONE * 0.1, Vector3(0.3, 0, 0.18), 2),
	])
	d["cavalete"] = item("Cavalete", ["fbc02d", "212121"], [
		part(BOX, Vector3(1.0, 0.08, 0.1), Vector3(0, 0.76, 0)),
		part(BOX, Vector3(0.05, 0.8, 0.05), Vector3(-0.42, 0.37, -0.13), 1, Vector3(-20, 0, 0)),
		part(BOX, Vector3(0.05, 0.8, 0.05), Vector3(-0.42, 0.37, 0.13), 1, Vector3(20, 0, 0)),
		part(BOX, Vector3(0.05, 0.8, 0.05), Vector3(0.42, 0.37, -0.13), 1, Vector3(-20, 0, 0)),
		part(BOX, Vector3(0.05, 0.8, 0.05), Vector3(0.42, 0.37, 0.13), 1, Vector3(20, 0, 0)),
		part(BOX, Vector3(0.9, 0.12, 0.02), Vector3(0, 0.62, 0.06), 0),
	])
	d["compressor"] = item("Compressor", ["e53935", "424242", "212121"], [
		part(CYLINDER, Vector3(0.4, 0.9, 0.4), Vector3(0, 0.35, 0), 0, Vector3(0, 0, 90)),
		on(BOX, Vector3(0.35, 0.3, 0.3), Vector3(0.12, 0.55, 0), 1),
		wheel(0.2, 0.06, Vector3(-0.3, 0.1, 0.2), 2),
		wheel(0.2, 0.06, Vector3(-0.3, 0.1, -0.2), 2),
		on(BOX, Vector3(0.05, 0.15, 0.3), Vector3(0.42, 0, 0), 2),
		part(BOX, Vector3(0.04, 0.04, 0.5), Vector3(-0.5, 0.65, 0), 1),
	])
	d["gerador"] = item("Gerador", ["fbc02d", "212121", "455a64"], [
		on(BOX, Vector3(0.65, 0.45, 0.45), Vector3(0, 0.08, 0)),
		on(BOX, Vector3(0.7, 0.04, 0.5), Vector3(0, 0.53, 0), 1),
		part(BOX, Vector3(0.04, 0.6, 0.04), Vector3(-0.33, 0.3, -0.23), 1),
		part(BOX, Vector3(0.04, 0.6, 0.04), Vector3(0.33, 0.3, -0.23), 1),
		part(BOX, Vector3(0.04, 0.6, 0.04), Vector3(-0.33, 0.3, 0.23), 1),
		part(BOX, Vector3(0.04, 0.6, 0.04), Vector3(0.33, 0.3, 0.23), 1),
		on(CYLINDER, Vector3(0.18, 0.12, 0.18), Vector3(0.15, 0.57, 0), 2),
		wheel(0.16, 0.06, Vector3(-0.36, 0.08, 0), 1),
	])
	d["cone"] = item("Cone", ["ff6f00", "fafafa", "212121"], [
		on(BOX, Vector3(0.4, 0.04, 0.4), Vector3.ZERO, 2),
		on(CONE, Vector3(0.32, 0.65, 0.32), Vector3(0, 0.04, 0)),
		part(CYLINDER, Vector3(0.2, 0.08, 0.2), Vector3(0, 0.38, 0), 1),
	])
	d["extintor"] = item("Extintor", ["c62828", "212121"], [
		on(CAPSULE, Vector3(0.2, 0.6, 0.2), Vector3.ZERO),
		on(CYLINDER, Vector3(0.05, 0.08, 0.05), Vector3(0, 0.6, 0), 1),
		part(BOX, Vector3(0.03, 0.03, 0.18), Vector3(0, 0.66, 0.07), 1),
		part(BOX, Vector3(0.03, 0.3, 0.03), Vector3(0, 0.4, 0.13), 1),
	])
	d["lixeira_industrial"] = item("Lixeira industrial", ["2e7d32", "1b5e20", "212121"], [
		on(BOX, Vector3(0.65, 1.0, 0.75), Vector3(0, 0.05, 0)),
		on(BOX, Vector3(0.7, 0.05, 0.8), Vector3(0, 1.05, 0), 1),
		wheel(0.2, 0.06, Vector3(-0.3, 0.1, -0.32), 2),
		wheel(0.2, 0.06, Vector3(0.3, 0.1, -0.32), 2),
	])
	d["capacete"] = item("Capacete", ["fdd835", "f9a825"], [
		on(SPHERE, Vector3(0.28, 0.22, 0.32), Vector3(0, 0.02, 0)),
		on(CYLINDER, Vector3(0.36, 0.02, 0.36), Vector3.ZERO, 1),
	])
	d["tanque_industrial"] = item("Tanque industrial", ["b0bec5", "78909c", "e65100"], [
		on(CYLINDER, Vector3(1.4, 1.8, 1.4), Vector3(0, 0.3, 0)),
		part(SPHERE, Vector3.ONE * 1.4, Vector3(0, 2.1, 0)),
		part(CYLINDER, Vector3(0.15, 1.2, 0.15), Vector3(0.6, 1.0, 0.5), 1, Vector3(90, 0, 0)),
		part(CYLINDER, Vector3(0.25, 0.08, 0.25), Vector3(0.6, 1.0, 0.75), 2, Vector3(90, 0, 0)),
	] + legs(Vector2(1.0, 1.0), 0.3, 0.1, 1))
	d["maquina"] = item("Máquina industrial", ["fbc02d", "455a64", "37474f"], [
		on(BOX, Vector3(2.4, 2.4, 2.4), Vector3.ZERO),
		on(CYLINDER, Vector3(0.5, 1.2, 0.5), Vector3(0.5, 2.4, 0), 1),
		part(BOX, Vector3(0.6, 0.5, 0.02), Vector3(-0.6, 1.4, 1.205), 2),
		part(BOX, Vector3(1.0, 0.6, 0.02), Vector3(0.4, 0.8, 1.205), 2),
	])
	d["esteira"] = item("Esteira", ["546e7a", "263238", "fbc02d"], [
		on(BOX, Vector3(2.0, 0.06, 1.0), Vector3(0, 0.8, 0), 1),
		part(BOX, Vector3(2.0, 0.12, 0.08), Vector3(0, 0.76, -0.54)),
		part(BOX, Vector3(2.0, 0.12, 0.08), Vector3(0, 0.76, 0.54)),
		part(BOX, Vector3(1.9, 0.04, 0.04), Vector3(0, 0.3, -0.5), 2),
		part(BOX, Vector3(1.9, 0.04, 0.04), Vector3(0, 0.3, 0.5), 2),
	] + legs(Vector2(1.9, 1.08), 0.72, 0.08), [
		hit(Vector3(2.0, 0.2, 1.16), Vector3(0, 0.76, 0)),
	] + leg_hits(Vector2(1.9, 1.08), 0.72, 0.08))
	return d


# --- Escritório e refeitório ----------------------------------------------------------

static func _office() -> Dictionary:
	var d := {}
	d["arquivo_aco"] = item("Arquivo de aço", ["90a4ae", "607d8b"], [
		on(BOX, Vector3(0.5, 1.3, 0.6), Vector3.ZERO),
		part(BOX, Vector3(0.42, 0.26, 0.01), Vector3(0, 0.2, 0.302), 1),
		part(BOX, Vector3(0.42, 0.26, 0.01), Vector3(0, 0.52, 0.302), 1),
		part(BOX, Vector3(0.42, 0.26, 0.01), Vector3(0, 0.84, 0.302), 1),
		part(BOX, Vector3(0.42, 0.26, 0.01), Vector3(0, 1.16, 0.302), 1),
	])
	d["impressora"] = item("Impressora", ["eceff1", "37474f", "fafafa"], [
		on(BOX, Vector3(0.5, 0.3, 0.45), Vector3.ZERO),
		on(BOX, Vector3(0.4, 0.04, 0.25), Vector3(0, 0.3, -0.05), 1),
		part(BOX, Vector3(0.3, 0.02, 0.2), Vector3(0, 0.12, 0.3), 2),
	])
	d["bebedouro"] = item("Bebedouro", ["eceff1", "4fc3f7", "1565c0"], [
		on(BOX, Vector3(0.35, 0.95, 0.35), Vector3.ZERO),
		on(CYLINDER, Vector3(0.3, 0.42, 0.3), Vector3(0, 0.95, 0), 1),
		part(BOX, Vector3(0.05, 0.05, 0.05), Vector3(-0.07, 0.75, 0.2), 2),
		part(BOX, Vector3(0.05, 0.05, 0.05), Vector3(0.07, 0.75, 0.2), 2),
	])
	d["maquina_venda"] = item("Máquina de venda", ["c62828", "b3e5fc", "212121"], [
		on(BOX, Vector3(0.9, 1.85, 0.8), Vector3.ZERO),
		part(BOX, Vector3(0.55, 1.2, 0.02), Vector3(-0.12, 1.15, 0.401), 1),
		part(BOX, Vector3(0.16, 0.6, 0.02), Vector3(0.32, 1.25, 0.401), 2),
		part(BOX, Vector3(0.55, 0.15, 0.02), Vector3(-0.12, 0.3, 0.401), 2),
	])
	d["mesa_refeitorio"] = item("Mesa do refeitório", ["eceff1", "78909c"], [
		part(BOX, Vector3(2.4, 0.05, 0.8), Vector3(0, 0.74, 0)),
	] + legs(Vector2(2.2, 0.6), 0.72, 0.06, 1), [
		hit(Vector3(2.4, 0.05, 0.8), Vector3(0, 0.74, 0)),
	] + leg_hits(Vector2(2.2, 0.6), 0.72, 0.06))
	d["banco_refeitorio"] = item("Banco do refeitório", ["1e88e5", "78909c"], [
		part(BOX, Vector3(2.2, 0.05, 0.35), Vector3(0, 0.45, 0)),
	] + legs(Vector2(2.0, 0.25), 0.43, 0.05, 1))
	d["mesa_escritorio"] = item("Mesa de escritório", ["eceff1", "78909c", "212121"], [
		part(BOX, Vector3(1.4, 0.04, 0.7), Vector3(0, 0.73, 0)),
		on(BOX, Vector3(0.04, 0.71, 0.66), Vector3(-0.66, 0, 0), 1),
		on(BOX, Vector3(0.04, 0.71, 0.66), Vector3(0.66, 0, 0), 1),
		on(BOX, Vector3(0.55, 0.36, 0.04), Vector3(0, 0.75, -0.2), 2),
		on(BOX, Vector3(0.15, 0.02, 0.12), Vector3(0, 0.75, -0.2), 2),
	], [
		hit(Vector3(1.4, 0.04, 0.7), Vector3(0, 0.73, 0)),
		hit(Vector3(0.04, 0.71, 0.66), Vector3(-0.66, 0.355, 0)),
		hit(Vector3(0.04, 0.71, 0.66), Vector3(0.66, 0.355, 0)),
		hit(Vector3(0.55, 0.38, 0.06), Vector3(0, 0.94, -0.2)),
	])
	d["armario_vestiario"] = item("Armário do vestiário", ["607d8b", "455a64"], [
		on(BOX, Vector3(0.5, 1.9, 0.5), Vector3.ZERO),
		part(BOX, Vector3(0.42, 0.04, 0.01), Vector3(0, 1.7, 0.252), 1),
		part(BOX, Vector3(0.42, 0.04, 0.01), Vector3(0, 1.62, 0.252), 1),
		part(BOX, Vector3(0.03, 0.15, 0.03), Vector3(0.17, 1.0, 0.26), 1),
	])
	d["maquina_cafe"] = item("Máquina de café", ["37474f", "8d6e63", "fafafa"], [
		on(BOX, Vector3(0.7, 1.75, 0.7), Vector3.ZERO),
		part(BOX, Vector3(0.5, 0.5, 0.02), Vector3(0, 1.3, 0.351), 1),
		part(BOX, Vector3(0.25, 0.3, 0.1), Vector3(0, 0.7, 0.33), 2),
	])
	return d
