@tool
class_name Hotspot
extends Control
## 部屋の中のクリックできる場所(仮素材の図形つき)。
## hotspot_id が空なら飾り(クリック不可)として描くだけ。
## 本番の絵ができたら、子に TextureRect を置いて draw_placeholder を切る。

signal pressed(hotspot_id: String)

enum Shape { RECT, ELLIPSE, DOOR }

@export var hotspot_id: String = ""
@export var label_key: String = ""
@export var fill_color: Color = Color(0.85, 0.75, 0.6):
	set(v):
		fill_color = v
		queue_redraw()
@export var shape: Shape = Shape.RECT:
	set(v):
		shape = v
		queue_redraw()
## この条件(GameState.check の書式)を満たすときだけ表示する
@export var visible_if: String = ""
@export var draw_placeholder: bool = true
@export var label_size: int = 30

var _hover := false


func _ready() -> void:
	if hotspot_id.is_empty():
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _hover = true; queue_redraw())
	mouse_exited.connect(func(): _hover = false; queue_redraw())
	if not Engine.is_editor_hint():
		GameState.changed.connect(refresh)
		refresh()


func refresh() -> void:
	if not visible_if.is_empty():
		visible = GameState.check(visible_if)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if hotspot_id.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit(hotspot_id)


func _draw() -> void:
	if not draw_placeholder:
		return
	var col := fill_color.lightened(0.15) if _hover else fill_color
	var line := Color(0.35, 0.27, 0.2)
	var width := 6.0 if _hover else 4.0
	var r := Rect2(Vector2.ZERO, size)
	match shape:
		Shape.ELLIPSE:
			var pts := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48.0
				pts.append(size * 0.5 + Vector2(cos(a), sin(a)) * size * 0.5)
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, line, width, true)
		Shape.DOOR:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.border_color = line
			sb.set_border_width_all(int(width))
			sb.corner_radius_top_left = int(size.x * 0.5)
			sb.corner_radius_top_right = int(size.x * 0.5)
			draw_style_box(sb, r)
			draw_circle(Vector2(size.x * 0.78, size.y * 0.55), 10.0, line)
		_:
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.border_color = line
			sb.set_border_width_all(int(width))
			sb.set_corner_radius_all(18)
			draw_style_box(sb, r)
	if not label_key.is_empty():
		var font := get_theme_default_font()
		var text := tr(label_key)
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, label_size)
		var pos := Vector2((size.x - ts.x) * 0.5, size.y * 0.5 + ts.y * 0.3)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 8, Color(1, 1, 1, 0.85))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, line)
