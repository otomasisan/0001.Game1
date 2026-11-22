extends PuzzleBase
## 謎7「ラジオ」: 雑音の強さを手がかりに周波数を合わせる。
## 合うと家畜市況の放送が聞こえる。答えが示す真実: 羊は「商品」だった。

const MIN_POS := 0
const MAX_POS := 30
const TARGET := 19          # 85.5 MHz
const STEP_MHZ := 0.5
const BASE_MHZ := 76.0

var pos := 4
var _freq: Label
var _noise: Label
var _meter: Control


func _init() -> void:
	title_key = "RADIO_TITLE"


func _build(a: Control) -> void:
	_freq = Label.new()
	_freq.position = Vector2(120, 30)
	_freq.size = Vector2(600, 90)
	_freq.add_theme_font_size_override("font_size", 64)
	_freq.add_theme_color_override("font_color", INK)
	a.add_child(_freq)

	_meter = Control.new()
	_meter.position = Vector2(120, 140)
	_meter.size = Vector2(1200, 60)
	_meter.draw.connect(_draw_meter)
	a.add_child(_meter)

	_noise = Label.new()
	_noise.position = Vector2(120, 220)
	_noise.size = Vector2(1200, 150)
	_noise.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_noise.add_theme_font_size_override("font_size", 34)
	_noise.add_theme_color_override("font_color", Color(0.45, 0.4, 0.36))
	a.add_child(_noise)

	make_button("◀◀", Vector2(120, 400), Vector2(140, 80), 30).pressed.connect(func(): tune(-4))
	make_button("◀", Vector2(280, 400), Vector2(140, 80), 34).pressed.connect(func(): tune(-1))
	make_button("▶", Vector2(440, 400), Vector2(140, 80), 34).pressed.connect(func(): tune(1))
	make_button("▶▶", Vector2(600, 400), Vector2(140, 80), 30).pressed.connect(func(): tune(4))
	var listen := make_button(tr("RADIO_LISTEN"), Vector2(860, 400), Vector2(360, 80), 34)
	listen.name = "ListenButton"
	listen.pressed.connect(listen_now)
	set_status("RADIO_HELP")
	_refresh()


func tune(d: int) -> void:
	if is_solved:
		return
	pos = clampi(pos + d, MIN_POS, MAX_POS)
	set_status("RADIO_HELP")
	_refresh()


func set_pos(p: int) -> void:
	pos = clampi(p, MIN_POS, MAX_POS)
	set_status("RADIO_HELP")
	_refresh()


## 0(雑音なし)〜1(雑音だけ)
func noise_level() -> float:
	return clampf(absi(pos - TARGET) / 8.0, 0.0, 1.0)


func listen_now() -> void:
	if is_solved:
		return
	if pos == TARGET:
		mark_solved()
	else:
		set_status("RADIO_WRONG")


func _refresh() -> void:
	_freq.text = "%.1f MHz" % (BASE_MHZ + pos * STEP_MHZ)
	var lv := noise_level()
	if lv >= 1.0:
		_noise.text = tr("RADIO_STATIC").repeat(10)
	else:
		# 近づくほど、放送の言葉が雑音のすきまから聞こえてくる
		var words := tr("RADIO_FRAGMENT")
		var out := ""
		var rng := RandomNumberGenerator.new()
		rng.seed = pos
		for ch in words:
			out += ch if rng.randf() > lv else tr("RADIO_STATIC").substr(0, 1)
		_noise.text = out
	_meter.queue_redraw()


func _draw_meter() -> void:
	var w := _meter.size.x
	_meter.draw_rect(Rect2(0, 0, w, 50), Color(1, 0.99, 0.95))
	_meter.draw_rect(Rect2(0, 0, w, 50), INK, false, 4.0)
	# 雑音の強さ(短いほど よく聞こえる)
	var lv := noise_level()
	_meter.draw_rect(Rect2(4, 4, (w - 8) * maxf(lv, 0.03), 42), Color(0.85, 0.55, 0.45))
	# 目盛りの針
	var x := w * float(pos - MIN_POS) / float(MAX_POS - MIN_POS)
	_meter.draw_line(Vector2(x, -10), Vector2(x, 60), INK, 5.0)
