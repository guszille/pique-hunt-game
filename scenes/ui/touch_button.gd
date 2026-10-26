class_name TouchButton
extends Control
## Botão redondo dos controles de toque. Quem decide qual dedo aperta é o
## TouchControls (que recebe os toques de todos os dedos); este nó só desenha
## e envia a ação de input, como se fosse a tecla correspondente.

var action := ""
var radius := 40.0
## Cor de destaque (ex.: verde quando a mira está num alvo válido).
var highlight := Color.TRANSPARENT:
	set(value):
		if highlight != value:
			highlight = value
			queue_redraw()
var pressed := false

var _label: Label


func _init(button_action: String, button_radius: float) -> void:
	action = button_action
	radius = button_radius
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * radius * 2.0
	size = custom_minimum_size
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_constant_override("outline_size", 4)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func set_text(text: String) -> void:
	if _label.text == text:
		return
	_label.text = text
	# Letra menor para nomes compridos (ex.: CONGELAR), para caber no círculo.
	var fit := radius * 1.7 / (maxi(text.length(), 1) * 0.7)
	_label.add_theme_font_size_override("font_size", clampi(int(minf(radius * 0.36, fit)), 10, 20))


## O toque em `point` (coordenadas da tela) cai neste botão? Há uma folga de 15%.
func hits(point: Vector2) -> bool:
	return is_visible_in_tree() and point.distance_to(global_position + size * 0.5) <= radius * 1.15


func press() -> void:
	if pressed:
		return
	pressed = true
	_send(true)
	queue_redraw()


func release() -> void:
	if not pressed:
		return
	pressed = false
	_send(false)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var fill := Color(1, 1, 1, 0.35) if pressed else Color(0, 0, 0, 0.35)
	draw_circle(center, radius, fill)
	if highlight.a > 0.0:
		draw_circle(center, radius, Color(highlight, 0.35))
	draw_arc(center, radius - 1.5, 0.0, TAU, 48, Color(1, 1, 1, 0.75), 3.0, true)


func _send(is_pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = is_pressed
	event.strength = 1.0 if is_pressed else 0.0
	Input.parse_input_event(event)
