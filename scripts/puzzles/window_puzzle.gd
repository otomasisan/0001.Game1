extends PuzzleBase
## 謎6「くもった窓」: 息を吹きかけると浮かぶ文字を、星の数の順に並べ替える。
## 正解は「おそとは えだよ」(英語版 PAINTED)。答えが示す真実: 窓の景色は描かれた絵。

## 最初の並び(正解の何文字目か)
const START := [3, 6, 0, 5, 1, 4, 2]
const TILE := Vector2(150, 190)

var order: Array[int] = []
var _letters: PackedStringArray
var _tiles: Array[Control] = []
var _selected := -1


func _init() -> void:
	title_key = "WINDOW_TITLE"


func _build(a: Control) -> void:
	_letters = PackedStringArray()
	for ch in tr("WINDOW_LETTERS"):
		_letters.append(ch)
	order.assign(START)
	a.draw.connect(_draw_glass)
	var n := order.size()
	var x0 := (PANEL_SIZE.x - n * TILE.x - (n - 1) * 20) * 0.5
	for i in n:
		var t := Control.new()
		t.name = "Tile%d" % i
		t.size = TILE
		t.position = Vector2(x0 + i * (TILE.x + 20), 120)
		t.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		t.gui_input.connect(_on_tile_input.bind(i))
		t.draw.connect(_draw_tile.bind(i))
		a.add_child(t)
		_tiles.append(t)
	set_status("WINDOW_HELP")


func _on_tile_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_tile(i)


func select_tile(i: int) -> void:
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
	for t in _tiles:
		t.queue_redraw()


func is_sorted() -> bool:
	for i in order.size():
		if order[i] != i:
			return false
	return true


## テスト用: 正しい並びにするための入れ替えを順に行う
func solve_by_swaps() -> void:
	for i in order.size():
		var j := order.find(i)
		if j != i:
			select_tile(i)
			select_tile(j)


func _draw_glass() -> void:
	var r := Rect2(60, 40, PANEL_SIZE.x - 120, 400)
	area.draw_rect(r, Color(0.86, 0.9, 0.92))
	area.draw_rect(r, INK, false, 6.0)
	area.draw_line(Vector2(r.get_center().x, r.position.y), Vector2(r.get_center().x, r.end.y), Color(INK, 0.25), 6.0)


func _draw_tile(i: int) -> void:
	var t := _tiles[i]
	var idx := order[i]
	var lift := -16.0 if i == _selected else 0.0
	var r := Rect2(Vector2(0, lift), TILE)
	var fog := Color(1, 1, 1, 0.55 if not is_solved else 0.8)
	t.draw_rect(r, fog)
	if i == _selected:
		t.draw_rect(r, Color(0.72, 0.42, 0.35), false, 5.0)
	var font := get_theme_default_font()
	var ch := _letters[idx] if idx < _letters.size() else "?"
	var ts := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 96)
	t.draw_string(font, Vector2((TILE.x - ts.x) * 0.5, lift + 120), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 96, Color(0.45, 0.5, 0.55))
	# 文字の下の、ゆびで かいた 星(正しい順番の数)
	var stars := idx + 1
	for s in stars:
		var cx := TILE.x * 0.5 + (s - (stars - 1) * 0.5) * 18.0
		t.draw_circle(Vector2(cx, lift + 160), 6.0, Color(0.95, 0.8, 0.35))
