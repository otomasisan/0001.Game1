extends Control
## タイトル画面: はじめから / つづきから / 言語 / おわる

var _buttons := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.99, 0.94, 0.86)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var moko := Moko.new()
	moko.position = Vector2(1180, 330)
	moko.size = Vector2(520, 420)
	add_child(moko)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(180, 200)
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_color", Color(0.35, 0.27, 0.2))
	add_child(title)
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.position = Vector2(190, 340)
	sub.add_theme_font_size_override("font_size", 34)
	sub.add_theme_color_override("font_color", Color(0.72, 0.42, 0.35))
	add_child(sub)

	var vb := VBoxContainer.new()
	vb.position = Vector2(190, 480)
	vb.add_theme_constant_override("separation", 20)
	add_child(vb)
	var ids := ["new", "continue", "language", "quit"]
	# エディタやデバッグ書き出しのときだけ、第2章へ飛ぶ確認用ボタンを出す
	if OS.is_debug_build():
		ids.insert(2, "debug_ch2")
	for id in ids:
		var b := Button.new()
		b.name = id
		b.custom_minimum_size = Vector2(440, 84)
		b.add_theme_font_size_override("font_size", 34)
		b.pressed.connect(_on_button.bind(id))
		vb.add_child(b)
		_buttons[id] = b

	var ver := Label.new()
	ver.text = "v%s  prototype" % ProjectSettings.get_setting("application/config/version", "0.1.0")
	ver.position = Vector2(40, 1020)
	ver.add_theme_font_size_override("font_size", 22)
	ver.add_theme_color_override("font_color", Color(0.5, 0.42, 0.35))
	add_child(ver)
	_refresh()
	_buttons["continue" if GameState.has_save() else "new"].grab_focus()


func _refresh() -> void:
	(get_node("Title") as Label).text = tr("GAME_TITLE")
	(get_node("Subtitle") as Label).text = tr("GAME_SUBTITLE")
	_buttons["new"].text = tr("UI_NEW_GAME")
	_buttons["continue"].text = tr("UI_CONTINUE")
	_buttons["continue"].disabled = not GameState.has_save()
	_buttons["language"].text = tr("UI_LANGUAGE")
	_buttons["quit"].text = tr("UI_QUIT")
	if _buttons.has("debug_ch2"):
		_buttons["debug_ch2"].text = tr("UI_DEBUG_CH2")


func _on_button(id: String) -> void:
	match id:
		"new":
			GameState.delete_save()
			GameState.new_game()
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"debug_ch2":
			GameState.debug_start_chapter(2)
			GameState.set_meta("pending_start", Story.CHAPTER_START.get(2, []))
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		"continue":
			if GameState.load_game():
				get_tree().change_scene_to_file("res://scenes/main.tscn")
		"language":
			GameState.set_locale("en" if TranslationServer.get_locale().begins_with("ja") else "ja")
			_refresh()
		"quit":
			get_tree().quit()
