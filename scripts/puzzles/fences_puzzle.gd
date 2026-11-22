extends PuzzleBase
## 謎9「ちかしつの さく」: 3×3 のスライドパズル。柵の区画を動かして、はしごから先へ道をつなぐ。
## できあがった図は、区画ごとに子どもの字で「だいどころ」「いま」…と書かれた、この家の間取りそのもの。
## 答えが示す真実: 家は羊舎の区画だった。

const SIZE := 3
const CELL := 170.0
## 正しい位置(左上から右へ)ごとの区画: [ラベルキー, 道がつながる向き N/E/S/W]
const PENS := [
	["FENCE_KIDS", "E"], ["FENCE_LIVING", "WES"], ["FENCE_BROTHER", "W"],
	["FENCE_KITCHEN", "SE"], ["FENCE_HALL", "NESW"], ["FENCE_PARENTS", "W"],
	["FENCE_DOOR", "N"], ["FENCE_BASEMENT", "N"],
]
const EMPTY := 8
const SCRAMBLE_MOVES := 40

## cells[位置] = 区画の番号(EMPTY は空き)
var cells: Array[int] = []
## 動かす前に空きがあった位置の記録(かきまぜた手順から)
var history: Array[int] = []
var _board: Control


func _init() -> void:
	title_key = "FENCES_TITLE"


func _build(a: Control) -> void:
	cells.assign(range(SIZE * SIZE))
	_scramble()
	_board = Control.new()
	_board.name = "Board"
	_board.size = Vector2(CELL * SIZE, CELL * SIZE)
	_board.position = Vector2((PANEL_SIZE.x - _board.size.x) * 0.5, 20)
	_board.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_board.gui_input.connect(_on_input)
	_board.draw.connect(_draw_board)
	a.add_child(_board)
	set_status("FENCES_HELP")


## 決まった手順でかきまぜる(毎回同じ並びで始まる)
func _scramble() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 217
	var last := -1
	var done := 0
	while done < SCRAMBLE_MOVES or is_sorted():
		var e := cells.find(EMPTY)
		var opts := _neighbors(e).filter(func(p): return p != last)
		var p: int = opts[rng.randi_range(0, opts.size() - 1)]
		last = e
		_swap(p, e)
		done += 1


func _neighbors(pos: int) -> Array:
	var r := pos / SIZE
	var c := pos % SIZE
	var out := []
	if r > 0: out.append(pos - SIZE)
	if r < SIZE - 1: out.append(pos + SIZE)
	if c > 0: out.append(pos - 1)
	if c < SIZE - 1: out.append(pos + 1)
	return out


func _swap(p: int, e: int) -> void:
	cells[e] = cells[p]
	cells[p] = EMPTY
	history.append(e)


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var c := int(event.position.x / CELL)
		var r := int(event.position.y / CELL)
		if c >= 0 and c < SIZE and r >= 0 and r < SIZE:
			slide(r * SIZE + c)


## 位置 pos の区画を、となりの空きへすべらせる
func slide(pos: int) -> bool:
	if is_solved:
		return false
	var e := cells.find(EMPTY)
	if not _neighbors(e).has(pos):
		return false
	_swap(pos, e)
	_board.queue_redraw()
	if is_sorted():
		mark_solved()
	return true


func is_sorted() -> bool:
	for i in cells.size():
		if cells[i] != i:
			return false
	return true


## テスト用: これまでの手(かきまぜた手順も含む)を逆にたどって元に戻す
func solve_by_undo() -> void:
	var path := history.duplicate()
	path.reverse()
	for e in path:
		slide(e)
		if is_solved:
			return


func _draw_board() -> void:
	var straw := Color(0.86, 0.78, 0.55)
	var fence := Color(0.62, 0.45, 0.3)
	_board.draw_rect(Rect2(Vector2.ZERO, _board.size), Color(0.42, 0.34, 0.27))
	var font := get_theme_default_font()
	for pos in cells.size():
		var id := cells[pos]
		if id == EMPTY:
			continue
		var o := Vector2(pos % SIZE, pos / SIZE) * CELL
		var r := Rect2(o + Vector2(4, 4), Vector2(CELL - 8, CELL - 8))
		_board.draw_rect(r, straw)
		var dirs: String = PENS[id][1]
		var mid := r.get_center()
		var ends := {"N": Vector2(mid.x, r.position.y), "S": Vector2(mid.x, r.end.y),
			"W": Vector2(r.position.x, mid.y), "E": Vector2(r.end.x, mid.y)}
		# 柵(道が通る向きは とびらが あいている)
		var sides := {"N": [r.position, Vector2(r.end.x, r.position.y)], "S": [Vector2(r.position.x, r.end.y), r.end],
			"W": [r.position, Vector2(r.position.x, r.end.y)], "E": [Vector2(r.end.x, r.position.y), r.end]}
		for d in sides:
			var a: Vector2 = sides[d][0]
			var b: Vector2 = sides[d][1]
			if dirs.contains(d):
				var m := (a + b) * 0.5
				var gap := (b - a).normalized() * 34.0
				_board.draw_line(a, m - gap, fence, 10.0)
				_board.draw_line(m + gap, b, fence, 10.0)
			else:
				_board.draw_line(a, b, fence, 10.0)
		# 道
		for d in dirs:
			_board.draw_line(mid, ends[d], Color(0.75, 0.33, 0.3, 0.85), 8.0)
		_board.draw_circle(mid, 9.0, Color(0.75, 0.33, 0.3))
		# 子どもの字の ラベル
		var label := tr(PENS[id][0])
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		_board.draw_string(font, Vector2(mid.x - ts.x * 0.5, r.position.y + 34), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	_board.draw_rect(Rect2(Vector2.ZERO, _board.size), INK, false, 6.0)
