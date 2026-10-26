extends Node
## Modo de controle: teclado e mouse, ou toque (celular).
## Começa em toque nos celulares e troca sozinho pelo último input real, então
## um notebook com tela de toque também funciona. Os controles de toque da HUD
## (scenes/ui/touch_controls.gd) mandam o arraste da câmera pelo sinal `look`.
##
## Testes no PC: `-- --mobile` simula um celular (toque emulado pelo mouse,
## interface maior e botões de toque).

signal changed
## Arraste de câmera no modo toque, em pixels da tela.
signal look(relative: Vector2)

## Nome dos botões de toque de cada ação (chaves de tradução).
const BUTTON_NAMES := {
	"jump": "PULAR",
	"transform": "VIRAR",
	"revert": "VOLTAR",
	"lock_rotation": "GIRAR",
	"freeze": "CONGELAR",
	"catch": "PEGAR",
	"scoreboard": "PLACAR",
	"pause": "PAUSA",
}
## Escala da interface em celulares: a tela é pequena e o dedo é grosso.
const HANDHELD_UI_SCALE := 1.35

var touch := false
## Celular de verdade ou simulado com `--mobile`: interface maior, sem botão "Sair".
var handheld := false

var _forced := false


func _ready() -> void:
	_forced = "--mobile" in OS.get_cmdline_user_args()
	handheld = OS.has_feature("mobile") or _forced
	touch = handheld
	if _forced:
		Input.emulate_touch_from_mouse = true
	if handheld:
		get_tree().root.content_scale_factor = HANDHELD_UI_SCALE


func _input(event: InputEvent) -> void:
	if _forced:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_touch(true)
	elif event is InputEventKey or event is InputEventJoypadButton:
		_set_touch(false)
	elif event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION:
		# Movimento de mouse emulado a partir do toque não conta.
		_set_touch(false)


## O jogo está recebendo comandos: mouse capturado no PC, ou modo toque.
func is_playing() -> bool:
	return touch or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## Nome traduzido do botão de toque de uma ação.
func button_name(action: String) -> String:
	return tr(BUTTON_NAMES.get(action, action))


func _set_touch(value: bool) -> void:
	if touch == value:
		return
	touch = value
	changed.emit()
