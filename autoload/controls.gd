extends Node
## Registra as ações de input usadas pelo jogo.
## Ações já definidas no Input Map do projeto têm prioridade e não são sobrescritas.

const KEYS := {
	"move_forward": KEY_W,
	"move_back": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"jump": KEY_SPACE,
	"transform": KEY_E,
	"revert": KEY_Q,
	"lock_rotation": KEY_R,
	"freeze": KEY_SHIFT,
	"scoreboard": KEY_TAB,
	"pause": KEY_ESCAPE,
}

const MOUSE_BUTTONS := {
	"catch": MOUSE_BUTTON_LEFT,
}


func _ready() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		InputMap.action_add_event(action, event)

	for action: String in MOUSE_BUTTONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTONS[action]
		InputMap.action_add_event(action, event)
