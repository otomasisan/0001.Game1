extends PuzzleBase
## 謎8「とうさんの どうぐばこ」: 工具箱の底の板4枚を入れ替えて、1枚の絵にする。
## 板にまたがる ふだの形と、ぐるっと引かれた線がつながると、番号 No.0217 が読める。
## 答えが示す真実: 家族には名前ではなく番号があった。

## 最初の並び(正しい何枚目か)
const START := [2, 0, 3, 1]
const DIGITS := ["0", "2", "1", "7"]
const BOARD := Vector2(230, 420)
const GAP := 24.0

var order: Array[int] = []
var _boards: Array[Control] = []
var _selected := -1


func _init() -> void:
	title_key = "TAG_TITLE"


func _build(a: Control) -> void:
	order.assign(START)
	var n := order.size()
	var x0 := (PANEL_SIZE.x - n * BOARD.x - (n - 1) * GAP) * 0.5
	for i in n:
		var b := Control.new()
		b.name = "Board%d" % i
		b.size = BOARD
		b.position = Vector2(x0 + i * (BOARD.x + GAP), 40)
		b.clip_contents = true
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.gui_input.connect(_on_input.bind(i))
		b.draw.connect(_draw_board.bind(i))
		a.add_child(b)
		_boards.append(b)
	set_status("TAG_HELP")


func _on_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_board(i)


func select_board(i: int) -> void:
	if is_solved:
		return
	if _selected == -1:
		_selected = i
	elif _selected == i:
		_selected = -1
	else:
		var tmp := order[i]
		order[i] = order[_selected]
		order[_selected] = tmp
		_selected = -1
		if is_sorted():
			mark_solved()
			set_status("TAG_SOLVED_STATUS")
	for b in _boards:
		b.queue_redraw()


func is_sorted() -> bool:
	for i in order.size():
		if order[i] != i:
			return false
	return true


## テスト用: 正しい並びにする
func solve_by_swaps() -> void:
	for i in order.size():
		var j := order.find(i)
		if j != i:
			select_board(i)
			select_board(j)


## 4枚ぶんの横幅にまたがる1枚の絵を、idx 枚目の位置で切り出して描く
func _draw_board(i: int) -> void:
	var b := _boards[i]
	var idx := order[i]
	var lift := -14.0 if i == _selected else 0.0
	var wood := Color(0.78, 0.62, 0.45)
	b.draw_rect(Rect2(0, lift, BOARD.x, BOARD.y), wood)
	# 木目
	for k in 5:
		var y := lift + 40 + k * 84 + (idx * 13 + k * 7) % 20
		b.draw_line(Vector2(0, y), Vector2(BOARD.x, y + 6), Color(0.62, 0.46, 0.32, 0.5), 3.0)
	var ox := -idx * BOARD.x
	var total := BOARD.x * DIGITS.size()
	var tag := Color(0.91, 0.76, 0.4)
	# ふだの形(左はしに ひもの あな)
	var r := Rect2(ox + 30, lift + 70, total - 60, 250)
	b.draw_rect(Rect2(r.position + Vector2(40, 0), r.size - Vector2(80, 0)), tag)
	b.draw_rect(Rect2(r.position + Vector2(0, 40), r.size - Vector2(0, 80)), tag)
	for c in [r.position + Vector2(40, 40), Vector2(r.end.x - 40, r.position.y + 40),
			Vector2(r.position.x + 40, r.end.y - 40), r.end - Vector2(40, 40)]:
		b.draw_circle(c, 40, tag)
	b.draw_circle(Vector2(ox + 74, lift + 195), 20, wood)
	b.draw_arc(Vector2(ox + 74, lift + 195), 20, 0, TAU, 32, INK, 5.0)
	# ふちどり
	var pts := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		var cx := r.position.x + 40 if cos(a) < 0 else r.end.x - 40
		var cy := r.position.y + 40 if sin(a) < 0 else r.end.y - 40
		pts.append(Vector2(cx + cos(a) * 40, cy + sin(a) * 40))
	pts.append(pts[0])
	b.draw_polyline(pts, INK, 6.0)
	# 板をまたいで つながる、ぐるっとした線
	var wave := PackedVector2Array()
	for k in 81:
		var x := total * k / 80.0
		wave.append(Vector2(ox + x, lift + 365 + 26 * sin(x / total * TAU * 1.5 + 0.7)))
	b.draw_polyline(wave, Color(0.72, 0.42, 0.35), 7.0)
	# 番号(1枚に1けた)
	var font := get_theme_default_font()
	var d: String = DIGITS[idx]
	var ts := font.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, 140)
	b.draw_string(font, Vector2((BOARD.x - ts.x) * 0.5 + (40 if idx == 0 else 0), lift + 250), d, HORIZONTAL_ALIGNMENT_LEFT, -1, 140, INK)
	if idx == 0:
		b.draw_string(font, Vector2(118, lift + 128), "No.", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, INK)
	b.draw_rect(Rect2(0, lift, BOARD.x, BOARD.y), INK, false, 5.0)
	if i == _selected:
		b.draw_rect(Rect2(3, lift + 3, BOARD.x - 6, BOARD.y - 6), Color(0.72, 0.42, 0.35), false, 8.0)
