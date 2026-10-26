extends Camera3D
## Câmera livre para quem entrou com a rodada em andamento (e para a tecla F2 de depuração).

const SPEED := 9.0
const MOUSE_SENSITIVITY := 0.0025
const TOUCH_SENSITIVITY := 0.006

var active := false


func _ready() -> void:
	InputMode.look.connect(func(relative: Vector2) -> void:
		if active:
			_turn(relative * TOUCH_SENSITIVITY))


func _unhandled_input(event: InputEvent) -> void:
	if active and event is InputEventMouseMotion and not InputMode.touch \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_turn(event.relative * MOUSE_SENSITIVITY)


func _process(delta: float) -> void:
	if not active or not InputMode.is_playing():
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var vertical := Input.get_action_strength("jump") - Input.get_action_strength("freeze")
	var direction := global_basis * Vector3(input.x, 0.0, input.y) + Vector3.UP * vertical
	global_position += direction.limit_length(1.0) * SPEED * delta


func _turn(amount: Vector2) -> void:
	rotation.y -= amount.x
	rotation.x = clampf(rotation.x - amount.y, -1.4, 1.4)
