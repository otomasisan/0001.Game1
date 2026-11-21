extends PuzzleBase
## 謎1「朝ごはんのお皿」: 母のメモの通りに、家族4人のお皿を5脚の椅子に並べる。
## 正解: 窓側から とうさん・ラム・モコ・(あき)・かあさん。
## 余る椅子(花のクッション)は家族以外の「誰か」=ミナの席。

const PLATES := ["", "father", "ram", "moko", "mother"]
const SOLUTION := ["father", "ram", "moko", "", "mother"]
const CHAIR_W := 190.0
const CHAIR_GAP := 40.0
const ROW_X := 190.0

var seats: Array[String] = ["", "", "", "", ""]
var _chairs: Array[Button] = []
var _memo: Label


func _init() -> void:
	title_key = "PLATES_TITLE"


func _build(a: Control) -> void:
	a.draw.connect(_draw_area)
	for i in 5:
		var x := ROW_X + i * (CHAIR_W + CHAIR_GAP)
		var b := make_button("", Vector2(x, 90), Vector2(CHAIR_W, 190), 28)
		b.name = "Chair%d" % i
		b.pressed.connect(cycle_seat.bind(i))
		_chairs.append(b)
	var cushion := Label.new()
	cushion.text = tr("PLATES_CUSHION")
	cushion.add_theme_font_size_override("font_size", 22)
	cushion.add_theme_color_override("font_color", Color(0.8, 0.45, 0.55))
	cushion.position = Vector2(ROW_X + 3 * (CHAIR_W + CHAIR_GAP), 290)
	a.add_child(cushion)

	var memo_btn := make_button(tr("UI_SHOW_MEMO"), Vector2(48, 500), Vector2(260, 64), 26)
	memo_btn.pressed.connect(func(): _memo.visible = not _memo.visible)
	_memo = Label.new()
	_memo.text = tr("PLATES_MEMO_SHORT")
	_memo.position = Vector2(340, 494)
	_memo.size = Vector2(1060, 100)
	_memo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_memo.add_theme_font_size_override("font_size", 26)
	_memo.add_theme_color_override("font_color", INK)
	_memo.visible = false
	a.add_child(_memo)
	set_status("PLATES_HELP")
	_refresh()


## 椅子をクリックするたび、まだ置いていないお皿を順番に置く(最後は「あき」に戻る)
func cycle_seat(i: int) -> void:
	if is_solved:
		return
	var idx := PLATES.find(seats[i])
	for step in range(1, PLATES.size() + 1):
		var cand: String = PLATES[(idx + step) % PLATES.size()]
		if cand.is_empty() or not seats.has(cand):
			seats[i] = cand
			break
	_refresh()
	_check()


func set_seats(values: Array) -> void:
	for i in 5:
		seats[i] = String(values[i])
	_refresh()
	_check()


func _check() -> void:
	if seats == SOLUTION:
		mark_solved()
	elif seats.count("") == 1:  # 4枚とも置いたのに違う
		set_status("PLATES_WRONG")
		shake(area)


func _refresh() -> void:
	for i in 5:
		var p := seats[i]
		_chairs[i].text = tr("PLATE_" + p.to_upper()) if not p.is_empty() else tr("PLATE_NONE")


func _draw_area() -> void:
	# 窓(左)・コンロ(右)・テーブル
	area.draw_rect(Rect2(30, 60, 120, 200), Color(0.7, 0.85, 0.95))
	area.draw_rect(Rect2(30, 60, 120, 200), INK, false, 4.0)
	area.draw_string(get_theme_default_font(), Vector2(46, 300), tr("PLATES_WINDOW"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	var sx := ROW_X + 5 * (CHAIR_W + CHAIR_GAP) - 10
	area.draw_rect(Rect2(sx, 110, 120, 150), Color(0.6, 0.6, 0.62))
	area.draw_rect(Rect2(sx, 110, 120, 150), INK, false, 4.0)
	area.draw_circle(Vector2(sx + 35, 140), 18, INK)
	area.draw_circle(Vector2(sx + 85, 140), 18, INK)
	area.draw_string(get_theme_default_font(), Vector2(sx + 6, 300), tr("PLATES_STOVE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	area.draw_rect(Rect2(ROW_X - 20, 340, 5 * (CHAIR_W + CHAIR_GAP), 100), Color(0.72, 0.52, 0.36))
	area.draw_rect(Rect2(ROW_X - 20, 340, 5 * (CHAIR_W + CHAIR_GAP), 100), INK, false, 4.0)
