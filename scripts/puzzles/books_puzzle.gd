extends PuzzleBase
## 謎3「絵本の本だな」: 表紙の絵(あさ・ひる・ゆうがた・よる)の順に絵本を並べると、
## 背表紙の文字が「まってて」(英語版は WAIT)になる。2冊をクリックすると入れ替わる。

const SOLUTION := ["morning", "noon", "evening", "night"]
const START := ["evening", "night", "morning", "noon"]
const BOOK_SIZE := Vector2(220, 420)
const COLORS := {
	"morning": Color(0.98, 0.85, 0.6),
	"noon": Color(0.65, 0.85, 0.95),
	"evening": Color(0.95, 0.6, 0.45),
	"night": Color(0.4, 0.42, 0.62),
}

var order: Array[String] = []
var _selected := -1
var _books: Array[Control] = []


func _init() -> void:
	title_key = "BOOKS_TITLE"


func _build(a: Control) -> void:
	order.assign(START)
	for i in 4:
		var b := Control.new()
		b.name = "Book%d" % i
		b.size = BOOK_SIZE
		b.position = _slot_pos(i)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.gui_input.connect(_on_book_input.bind(i))
		b.draw.connect(_draw_book.bind(i))
		a.add_child(b)
		_books.append(b)
	a.draw.connect(func(): a.draw_rect(Rect2(170, 500, 1100, 30), Color(0.6, 0.42, 0.28)))
	set_status("BOOKS_HELP")


func _slot_pos(i: int) -> Vector2:
	return Vector2(200 + i * (BOOK_SIZE.x + 50), 80)


func _on_book_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_book(i)


func select_book(i: int) -> void:
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
		if order == SOLUTION:
			mark_solved()
	for b in _books:
		b.queue_redraw()


func _draw_book(i: int) -> void:
	var b := _books[i]
	var id := order[i]
	var lift := -30.0 if i == _selected else 0.0
	var r := Rect2(Vector2(0, lift + 30), BOOK_SIZE - Vector2(0, 30))
	b.draw_rect(r, COLORS[id])
	b.draw_rect(r, INK, false, 5.0 if i == _selected else 3.0)
	# 表紙の絵: 太陽(または月)の位置で時刻を表す
	var sky := Rect2(r.position + Vector2(20, 20), Vector2(r.size.x - 40, 160))
	b.draw_rect(sky, COLORS[id].lightened(0.35))
	b.draw_line(sky.position + Vector2(0, 130), sky.position + Vector2(sky.size.x, 130), INK, 3.0)
	match id:
		"morning":
			b.draw_circle(sky.position + Vector2(40, 115), 26, Color(1.0, 0.7, 0.3))
		"noon":
			b.draw_circle(sky.position + Vector2(sky.size.x * 0.5, 40), 28, Color(1.0, 0.8, 0.2))
		"evening":
			b.draw_circle(sky.position + Vector2(sky.size.x - 40, 115), 26, Color(0.9, 0.35, 0.2))
		"night":
			b.draw_circle(sky.position + Vector2(sky.size.x * 0.5, 50), 26, Color(1, 0.97, 0.8))
			b.draw_circle(sky.position + Vector2(sky.size.x * 0.5 + 12, 42), 22, COLORS[id].lightened(0.35))
	# 背表紙の文字
	var font := get_theme_default_font()
	var ch := tr("BOOK_SPINE_" + id.to_upper())
	var ts := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 120)
	var pos := Vector2((r.size.x - ts.x) * 0.5, r.position.y + 330)
	b.draw_string(font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 120, INK if not is_solved else Color(0.72, 0.3, 0.3))
