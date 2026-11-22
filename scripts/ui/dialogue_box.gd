class_name DialogueBox
extends Control
## 画面下の会話ウィンドウ。表示中は画面全体のクリックを受けて次のページへ送る。
## テキスト中の "|" でページを区切る。

signal advanced
## 会話ウィンドウが開いた / 閉じた(部屋のモコを隠すのに使う)
signal active_changed(active: bool)

const SPEAKER_KEYS := {"moko": "SPEAKER_MOKO", "poppo": "SPEAKER_POPPO"}
## 話し手の立ち絵(会話ウィンドウの右上に出す)
const PORTRAITS := {
	"moko": "res://assets/characters/moko.png",
	"poppo": "res://assets/characters/poppo.png",
}
const PORTRAIT_SIZE := Vector2(260, 260)
const CHARS_PER_SEC := 40.0

var _panel: PanelContainer
var _name_label: Label
var _text: Label
var _tween: Tween
var _active := false
var _portrait: TextureRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.93, 0.96)
	sb.border_color = Color(0.35, 0.27, 0.2)
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(28)
	sb.set_content_margin_all(36)
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.position = Vector2(160, 760)
	_panel.custom_minimum_size = Vector2(1600, 260)
	_panel.size = _panel.custom_minimum_size
	# パネルがクリックを横取りしないように(ウィンドウの上をクリックしても次へ進む)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size = PORTRAIT_SIZE
	# 会話ウィンドウの右上に、ふちに腰かけるように置く(本文と重ならない位置)
	_portrait.position = Vector2(1480, 760 - PORTRAIT_SIZE.y + 30)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.visible = false
	add_child(_portrait)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_panel.add_child(vb)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 30)
	_name_label.add_theme_color_override("font_color", Color(0.72, 0.42, 0.35))
	vb.add_child(_name_label)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(1520, 150)
	_text.add_theme_font_size_override("font_size", 38)
	_text.add_theme_color_override("font_color", Color(0.3, 0.23, 0.18))
	_text.add_theme_constant_override("line_spacing", 10)
	vb.add_child(_text)


## 翻訳キーを表示し、全ページ読み終わるまで待つ
func show_key(key: String, speaker: String = "", fmt: Dictionary = {}) -> void:
	var text := tr(key)
	if not fmt.is_empty():
		text = text.format(fmt)
	await show_text(text, speaker)


func show_text(text: String, speaker: String = "") -> void:
	_name_label.text = tr(SPEAKER_KEYS[speaker]) if SPEAKER_KEYS.has(speaker) else ""
	_name_label.visible = not _name_label.text.is_empty()
	_portrait.visible = PORTRAITS.has(speaker)
	if _portrait.visible:
		_portrait.texture = load(PORTRAITS[speaker])
	visible = true
	if not _active:
		_active = true
		active_changed.emit(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for page in text.split("|"):
		_text.text = page.strip_edges()
		_text.visible_ratio = 0.0
		if _tween:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.2, _text.text.length() / CHARS_PER_SEC))
		await advanced
	_active = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_changed.emit(false)


func is_active() -> bool:
	return _active


## クリック / 決定キーで呼ぶ。文字送り中なら全文を出し、出し切っていれば次へ
func advance() -> void:
	if not _active:
		return
	if _text.visible_ratio < 1.0:
		if _tween:
			_tween.kill()
		_text.visible_ratio = 1.0
		return
	advanced.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		advance()


func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()
