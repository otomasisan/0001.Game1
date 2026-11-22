class_name PuzzleBase
extends Control
## 謎の画面の共通部分: 背景を暗くし、中央に紙のパネルと「もどる」ボタンを置く。
## 派生クラスは _build(area) で中身を作り、正解したら mark_solved() を呼ぶ。

signal solved
signal closed

const PANEL_SIZE := Vector2(1440, 820)
const INK := Color(0.35, 0.27, 0.2)

@export var title_key: String = ""

var is_solved := false
var area: Control
var _status: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.15, 0.1, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.9)
	sb.border_color = INK
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(32)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = (Vector2(1920, 1080) - PANEL_SIZE) * 0.5 + Vector2(0, -40)
	panel.size = PANEL_SIZE
	add_child(panel)

	var title := Label.new()
	title.text = tr(title_key)
	title.position = Vector2(48, 32)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", INK)
	panel.add_child(title)

	_status = Label.new()
	_status.position = Vector2(48, PANEL_SIZE.y - 84)
	_status.size = Vector2(PANEL_SIZE.x - 400, 60)
	_status.add_theme_font_size_override("font_size", 32)
	_status.add_theme_color_override("font_color", Color(0.72, 0.42, 0.35))
	panel.add_child(_status)

	var back := Button.new()
	back.name = "BackButton"
	back.text = tr("UI_BACK")
	back.focus_mode = Control.FOCUS_NONE
	back.add_theme_font_size_override("font_size", 30)
	back.position = Vector2(PANEL_SIZE.x - 280, PANEL_SIZE.y - 104)
	back.custom_minimum_size = Vector2(240, 72)
	back.pressed.connect(func(): if not is_solved: closed.emit())
	panel.add_child(back)

	area = Control.new()
	area.position = Vector2(0, 110)
	area.size = Vector2(PANEL_SIZE.x, PANEL_SIZE.y - 220)
	panel.add_child(area)
	_build(area)


## 派生クラスで上書きする
func _build(_area: Control) -> void:
	pass


func set_status(key: String) -> void:
	_status.text = tr(key) if not key.is_empty() else ""


func mark_solved() -> void:
	if is_solved:
		return
	is_solved = true
	set_status("PUZZLE_SOLVED")
	solved.emit()


## 不正解のときにパネルを小さくゆらす
func shake(node: Control) -> void:
	var base := node.position
	var t := create_tween()
	for i in 4:
		t.tween_property(node, "position", base + Vector2(14 if i % 2 == 0 else -14, 0), 0.05)
	t.tween_property(node, "position", base, 0.05)


func make_button(text: String, pos: Vector2, sz: Vector2, font_size: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos
	b.custom_minimum_size = sz
	b.size = sz
	b.add_theme_font_size_override("font_size", font_size)
	area.add_child(b)
	return b
