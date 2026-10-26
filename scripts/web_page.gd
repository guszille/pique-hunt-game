class_name WebPage
extends RefCounted
## Ajudas para a versão que roda no navegador (exportação Web).


static func is_web() -> bool:
	return OS.has_feature("web")


## iPhone/iPad no navegador: o Safari não tem tela cheia para páginas.
static func is_ios() -> bool:
	return OS.has_feature("web_ios")


## Endereço da página (ex.: 192.168.0.10), que é também o do host da partida.
static func host_name() -> String:
	if not is_web():
		return ""
	var host = JavaScriptBridge.eval("window.location.hostname", true)
	return str(host) if host else ""


static func can_fullscreen() -> bool:
	return is_web() and not is_ios()


static func toggle_fullscreen() -> void:
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
