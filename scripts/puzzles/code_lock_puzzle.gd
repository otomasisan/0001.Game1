extends PuzzleBase
## 数字のダイヤル錠(使い回し用の部品)。シーン側の設定だけで別の錠を作れる。
##   謎4 小箱: カレンダーの丸の日付(3・17・24)
##   謎5 引き出し: 兄とモコが背比べで並んだときの歳(4・5)

@export var help_key: String = ""
## 錠に貼ってある紙(ヒント)。空なら出さない
@export var note_key: String = ""
## 各ダイヤルの下に出す名前(翻訳キー)。空文字なら名前なし
@export var wheel_labels: PackedStringArray = []
@export var wheel_min: int = 0
@export var wheel_max: int = 9
@export var answer: Array[int] = []
@export var wrong_key: String = "LOCK_WRONG"

var values: Array[int] = []
var _value_labels: Array[Label] = []
var _wheels_box: Control


func _build(a: Control) -> void:
	var n := answer.size()
	var w := 170.0
	var gap := 50.0
	var x0 := (PANEL_SIZE.x - (n * w + (n - 1) * gap)) * 0.5
	_wheels_box = Control.new()
	_wheels_box.size = a.size
	a.add_child(_wheels_box)
	for i in n:
		values.append(wheel_min)
		var x := x0 + i * (w + gap)
		var up := make_button("▲", Vector2(x, 40), Vector2(w, 70), 34)
		up.pressed.connect(turn.bind(i, 1))
		var plate := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 0.99, 0.95)
		sb.border_color = INK
		sb.set_border_width_all(5)
		sb.set_corner_radius_all(16)
		plate.add_theme_stylebox_override("panel", sb)
		plate.position = Vector2(x, 124)
		plate.size = Vector2(w, 140)
		_wheels_box.add_child(plate)
		var l := Label.new()
		l.size = plate.size
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 80)
		l.add_theme_color_override("font_color", INK)
		plate.add_child(l)
		_value_labels.append(l)
		var down := make_button("▼", Vector2(x, 278), Vector2(w, 70), 34)
		down.pressed.connect(turn.bind(i, -1))
		if i < wheel_labels.size() and not wheel_labels[i].is_empty():
			var name_l := Label.new()
			name_l.text = tr(wheel_labels[i])
			name_l.position = Vector2(x, 356)
			name_l.size = Vector2(w, 40)
			name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_l.add_theme_font_size_override("font_size", 26)
			name_l.add_theme_color_override("font_color", INK)
			a.add_child(name_l)
	var open := make_button(tr("LOCK_OPEN"), Vector2((PANEL_SIZE.x - 320) * 0.5, 420), Vector2(320, 80), 34)
	open.name = "OpenButton"
	open.pressed.connect(try_open)
	if not note_key.is_empty():
		var note := Label.new()
		note.text = tr(note_key)
		note.position = Vector2(48, 516)
		note.size = Vector2(PANEL_SIZE.x - 96, 70)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", 28)
		note.add_theme_color_override("font_color", Color(0.5, 0.4, 0.32))
		a.add_child(note)
	set_status(help_key)
	_refresh()


## ダイヤルを回す(端まで行くと反対側に戻る)
func turn(i: int, d: int) -> void:
	if is_solved:
		return
	var span := wheel_max - wheel_min + 1
	values[i] = wheel_min + posmod(values[i] - wheel_min + d, span)
	_refresh()


func set_values(v: Array) -> void:
	for i in values.size():
		values[i] = int(v[i])
	_refresh()


func try_open() -> void:
	if is_solved:
		return
	if values == answer:
		mark_solved()
	else:
		set_status(wrong_key)
		shake(_wheels_box)


func _refresh() -> void:
	for i in values.size():
		_value_labels[i].text = str(values[i])
