extends PuzzleBase
## 謎10「やぶれた てがみ」: 横に裂かれた母の手紙を、ちぎれた ふちが合うように並べ、
## さかさまの切れはしは ひっくり返す。2枚を順にクリックで入れかえ、同じ切れはしを2回で ひっくり返す。
## 答えが示す真実: モコだけが残されたのは、ミナがお願いしてくれたから。

const LINES := 6
const START := [3, 0, 5, 1, 4, 2]
const START_FLIPPED := [false, true, false, false, true, false]
const STRIP := Vector2(1100, 74)
const GAP := 10.0

var order: Array[int] = []
var flipped: Array[bool] = []
var _strips: Array[Control] = []
var _selected := -1
## 切れ目 k(k 行目と k+1 行目の あいだ)の ぎざぎざ
var _edges: Array[PackedFloat32Array] = []


func _init() -> void:
	title_key = "LETTER_TITLE"


func _build(a: Control) -> void:
	order.assign(START)
	flipped.assign(START_FLIPPED)
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	for k in LINES + 1:
		var e := PackedFloat32Array()
		for j in 23:
			e.append(0.0 if k == 0 or k == LINES else rng.randf_range(-9.0, 9.0))
		_edges.append(e)
	for i in LINES:
		var s := Control.new()
		s.name = "Strip%d" % i
		s.size = STRIP
		s.position = Vector2((PANEL_SIZE.x - STRIP.x) * 0.5, 4 + i * (STRIP.y + GAP))
		s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		s.gui_input.connect(_on_input.bind(i))
		s.draw.connect(_draw_strip.bind(i))
		a.add_child(s)
		_strips.append(s)
	set_status("LETTER_HELP")


func _on_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_strip(i)


## 1回目で えらぶ。ちがう切れはしで 入れかえ、同じ切れはしで ひっくり返す
func select_strip(i: int) -> void:
	if is_solved:
		return
	if _selected == -1:
		_selected = i
	elif _selected == i:
		flipped[i] = not flipped[i]
		_selected = -1
	else:
		var t := order[i]
		order[i] = order[_selected]
		order[_selected] = t
		var f := flipped[i]
		flipped[i] = flipped[_selected]
		flipped[_selected] = f
		_selected = -1
	if is_done():
		mark_solved()
	for s in _strips:
		s.queue_redraw()


func is_done() -> bool:
	for i in LINES:
		if order[i] != i or flipped[i]:
			return false
	return true


## テスト用: 正しい並びにして、さかさまを直す
func solve_all() -> void:
	for i in LINES:
		var j := order.find(i)
		if j != i:
			select_strip(i)
			select_strip(j)
	for i in LINES:
		if flipped[i]:
			select_strip(i)
			select_strip(i)


func _edge_points(k: int, y: float, reverse: bool) -> PackedVector2Array:
	var e := _edges[k]
	var pts := PackedVector2Array()
	for j in e.size():
		var x := STRIP.x * j / (e.size() - 1)
		pts.append(Vector2(x, y + e[j]))
	if reverse:
		pts.reverse()
	return pts


func _draw_strip(i: int) -> void:
	var s := _strips[i]
	var idx := order[i]
	var paper := Color(0.97, 0.94, 0.86)
	if flipped[i]:
		s.draw_set_transform(STRIP, PI, Vector2.ONE)
	# 上のふちは切れ目 idx、下のふちは切れ目 idx+1
	var poly := _edge_points(idx, 6, false)
	poly.append_array(_edge_points(idx + 1, STRIP.y - 6, true))
	s.draw_colored_polygon(poly, paper)
	var outline := poly.duplicate()
	outline.append(poly[0])
	s.draw_polyline(outline, Color(INK, 0.7), 3.0)
	var font := get_theme_default_font()
	var text := tr("LETTER_LINE_%d" % (idx + 1))
	s.draw_string(font, Vector2(40, STRIP.y * 0.5 + 12), text, HORIZONTAL_ALIGNMENT_LEFT, STRIP.x - 80, 34, Color(0.32, 0.3, 0.42))
	s.draw_set_transform(Vector2.ZERO)
	if i == _selected:
		s.draw_rect(Rect2(Vector2(-6, 0), STRIP + Vector2(12, 0)), Color(0.72, 0.42, 0.35), false, 5.0)
