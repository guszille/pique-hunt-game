extends Node
## Idioma do jogo. Os textos do código e das cenas são escritos em português e
## servem de chave de tradução; `locale/en.po` traz as versões em inglês.
## A escolha do jogador fica salva em `user://settings.cfg`.
##
## Avisos que o host manda para todos viajam como mensagem: [chave, args...].
## Cada jogador traduz no próprio idioma com `format()`. Argumentos StringName
## (ex.: nome de mapa, &"Casa") também são traduzidos; String fica como está
## (nomes de jogadores).

signal changed

const LANGUAGES: Array[Dictionary] = [
	{"code": "pt_BR", "name": "Português (Brasil)"},
	{"code": "en", "name": "English"},
]
const SETTINGS_PATH := "user://settings.cfg"

var current := "pt_BR"


func _ready() -> void:
	var config := ConfigFile.new()
	var saved := ""
	if config.load(SETTINGS_PATH) == OK:
		saved = str(config.get_value("general", "language", ""))
	# Testes: `-- --lang=en` força um idioma (o Network ainda não leu a linha de comando).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--lang="):
			saved = arg.substr(7)
	if _index_of(saved) < 0:
		saved = "pt_BR" if OS.get_locale_language() == "pt" else "en"
	_apply(saved)


func set_language(code: String) -> void:
	if _index_of(code) < 0 or code == current:
		return
	_apply(code)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("general", "language", code)
	config.save(SETTINGS_PATH)
	changed.emit()


func index() -> int:
	return _index_of(current)


## Texto de uma mensagem [chave, args...] no idioma deste jogador.
func format(message: Array) -> String:
	if message.is_empty():
		return ""
	var text := tr(str(message[0]))
	if message.size() == 1:
		return text
	var args := []
	for arg in message.slice(1):
		args.append(tr(arg) if arg is StringName else arg)
	return text % args


func _apply(code: String) -> void:
	current = code
	TranslationServer.set_locale(code)


func _index_of(code: String) -> int:
	for i in LANGUAGES.size():
		if LANGUAGES[i].code == code:
			return i
	return -1
