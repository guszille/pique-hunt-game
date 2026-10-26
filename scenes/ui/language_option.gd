extends OptionButton
## Lista de idiomas (cada um escrito na própria língua) que troca o idioma do jogo.


func _ready() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	clear()
	for language in Language.LANGUAGES:
		add_item(language.name)
	select(Language.index())
	item_selected.connect(func(i: int) -> void: Language.set_language(Language.LANGUAGES[i].code))
