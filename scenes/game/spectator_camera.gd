extends Camera3D
## Câmera livre para quem entrou com a rodada em andamento (e para a tecla F2 de depuração).

const SPEED := 9.0
const MOUSE_SENSITIVITY := 0.0025

var active := false


func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * MOUSE_SENSITIVITY
		rotation.x = clampf(rotation.x - event.relative.y * MOUSE_SENSITIVITY, -1.4, 1.4)


func _process(delta: float) -> void:
	if not active or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var vertical := Input.get_action_strength("jump") - Input.get_action_strength("freeze")
	var direction := global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * vertical
	global_position += direction.limit_length(1.0) * SPEED * delta
