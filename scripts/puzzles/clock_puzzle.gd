extends PuzzleBase
## 謎2「ハト時計」: 針を、母のメモに書かれた帰宅時刻(6:40)に合わせる。
## 答えが示す真実: 合わせても針は二度と動かない(時計は止まったまま)。

const TARGET_HOUR := 6
const TARGET_MINUTE := 40

var hour := 12
var minute := 0
var _face: Control


func _init() -> void:
	title_key = "CLOCK_TITLE"


func _build(a: Control) -> void:
	_face = Control.new()
	_face.position = Vector2(120, 20)
	_face.size = Vector2(540, 540)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.draw.connect(_draw_face)
	a.add_child(_face)

	var lx := 780.0
	_label(tr("CLOCK_LONG_HAND"), Vector2(lx, 60))
	make_button("◀", Vector2(lx, 110), Vector2(120, 90), 40).pressed.connect(func(): add_minutes(-5))
	make_button("▶", Vector2(lx + 140, 110), Vector2(120, 90), 40).pressed.connect(func(): add_minutes(5))
	_label(tr("CLOCK_SHORT_HAND"), Vector2(lx, 240))
	make_button("◀", Vector2(lx, 290), Vector2(120, 90), 40).pressed.connect(func(): add_hours(-1))
	make_button("▶", Vector2(lx + 140, 290), Vector2(120, 90), 40).pressed.connect(func(): add_hours(1))
	var ok := make_button(tr("CLOCK_CONFIRM"), Vector2(lx, 440), Vector2(400, 90), 34)
	ok.name = "ConfirmButton"
	ok.pressed.connect(confirm)
	set_status("CLOCK_HELP")


func _label(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 30)
	l.add_theme_color_override("font_color", INK)
	area.add_child(l)


func add_minutes(d: int) -> void:
	if is_solved:
		return
	var total := (hour % 12) * 60 + minute + d
	total = posmod(total, 12 * 60)
	hour = total / 60
	if hour == 0:
		hour = 12
	minute = total % 60
	_face.queue_redraw()


func add_hours(d: int) -> void:
	add_minutes(d * 60)


func set_time(h: int, m: int) -> void:
	hour = h
	minute = m
	_face.queue_redraw()


func confirm() -> void:
	if is_solved:
		return
	if hour % 12 == TARGET_HOUR % 12 and minute == TARGET_MINUTE:
		mark_solved()
		_face.queue_redraw()
	else:
		set_status("CLOCK_WRONG")
		shake(_face)


func _draw_face() -> void:
	var c := _face.size * 0.5
	var r := _face.size.x * 0.45
	var font := get_theme_default_font()
	# 屋根つきのハト時計
	_face.draw_colored_polygon(PackedVector2Array([c + Vector2(-r - 30, -r + 10), c + Vector2(0, -r - 90), c + Vector2(r + 30, -r + 10)]), Color(0.55, 0.36, 0.24))
	_face.draw_circle(c, r + 14, INK)
	_face.draw_circle(c, r, Color(1, 0.98, 0.92))
	for i in range(1, 13):
		var a := TAU * i / 12.0 - PI / 2
		var p := c + Vector2(cos(a), sin(a)) * (r - 42)
		var s := str(i)
		var ts := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 34)
		_face.draw_string(font, p + Vector2(-ts.x * 0.5, ts.y * 0.3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, INK)
	var ma := TAU * minute / 60.0 - PI / 2
	var ha := TAU * ((hour % 12) + minute / 60.0) / 12.0 - PI / 2
	_face.draw_line(c, c + Vector2(cos(ha), sin(ha)) * r * 0.5, INK, 14.0, true)
	_face.draw_line(c, c + Vector2(cos(ma), sin(ma)) * r * 0.8, INK, 8.0, true)
	_face.draw_circle(c, 14, INK)
	# 小窓(正解するとポッポが顔を出す)
	var door := Rect2(c + Vector2(-34, -r - 70), Vector2(68, 56))
	_face.draw_rect(door, Color(0.3, 0.2, 0.14) if not is_solved else Color(0.98, 0.9, 0.7))
	if is_solved:
		_face.draw_circle(door.get_center(), 20, Color(0.55, 0.62, 0.7))
		_face.draw_circle(door.get_center() + Vector2(-6, -4), 4, INK)
