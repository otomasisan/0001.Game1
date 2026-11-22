extends Node
## ゲーム全体の進行状態(フラグ・持ち物・現在の部屋・章)と、セーブ/ロード、
## 翻訳テキストの読み込みを受け持つ。autoload 名は "GameState"。

signal changed
signal inventory_changed

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.cfg"
const TEXT_CSV := "res://i18n/text.csv"
const SAVE_VERSION := 1

var flags: Dictionary = {}
var inventory: Array[String] = []
var room: String = "kitchen"
var chapter: int = 1

## ポッポのヒント: いまの段階と、何段目まで見せたか
var hint_stage: String = ""
var hint_tier: int = 0


func _ready() -> void:
	_load_translations()
	_load_settings()
	get_tree().root.theme = _make_theme()


## 絵本風のボタン(仮)。本番の UI 素材ができたら .tres のテーマに置き換える
func _make_theme() -> Theme:
	var theme := Theme.new()
	var ink := Color(0.35, 0.27, 0.2)
	var states := {
		"normal": Color(0.99, 0.93, 0.8),
		"hover": Color(1.0, 0.97, 0.88),
		"pressed": Color(0.93, 0.8, 0.66),
		"hover_pressed": Color(0.95, 0.84, 0.7),
		"disabled": Color(0.9, 0.87, 0.82),
		"focus": Color(0, 0, 0, 0),
	}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.border_color = ink if state != "disabled" else Color(0.7, 0.65, 0.6)
		sb.set_border_width_all(4 if state != "focus" else 0)
		sb.set_corner_radius_all(22)
		sb.set_content_margin_all(12)
		if state == "focus":
			sb.draw_center = false
			sb.border_color = Color(0.72, 0.42, 0.35)
			sb.set_border_width_all(4)
		theme.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(c, "Button", ink)
	theme.set_color("font_disabled_color", "Button", Color(0.65, 0.6, 0.55))
	return theme


# --- 進行状態 ---------------------------------------------------------------

func new_game() -> void:
	flags = {}
	inventory = []
	room = "kitchen"
	chapter = 1
	hint_stage = ""
	hint_tier = 0
	changed.emit()
	inventory_changed.emit()


## 確認用: 第1章を解き終えた状態から第2章を始める(デバッグ版のタイトルから呼ぶ)
const CHAPTER1_FLAGS := ["intro_done", "read_memo", "got_plates", "solved_plates", "clock_wound",
	"solved_clock", "kids_door_open", "solved_books", "chapter1_clear"]


func debug_start_chapter(n: int) -> void:
	new_game()
	if n >= 2:
		for f in CHAPTER1_FLAGS:
			flags[f] = true
		room = "kids_room"
	chapter = n
	changed.emit()


func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value
	changed.emit()


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func add_item(item: String) -> void:
	if not inventory.has(item):
		inventory.append(item)
		inventory_changed.emit()
		changed.emit()


func remove_item(item: String) -> void:
	if inventory.has(item):
		inventory.erase(item)
		inventory_changed.emit()
		changed.emit()


func has_item(item: String) -> bool:
	return inventory.has(item)


## 条件文字列を評価する。
##   "flag"         フラグが立っている
##   "!cond"        否定
##   "has:item"     持ち物にある
##   "chapter>=N"   章がN以上
func check(cond: String) -> bool:
	if cond.is_empty():
		return true
	if cond.begins_with("!"):
		return not check(cond.substr(1))
	if cond.begins_with("has:"):
		return has_item(cond.substr(4))
	if cond.begins_with("chapter>="):
		return chapter >= int(cond.substr(9))
	return has_flag(cond)


func check_all(conds: Array) -> bool:
	for c in conds:
		if not check(String(c)):
			return false
	return true


# --- セーブ/ロード ------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"flags": flags,
		"inventory": inventory,
		"room": room,
		"chapter": chapter,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("セーブに失敗: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("セーブデータが壊れています")
		return false
	flags = data.get("flags", {})
	inventory.clear()
	for item in data.get("inventory", []):
		inventory.append(String(item))
	room = String(data.get("room", "kitchen"))
	chapter = int(data.get("chapter", 1))
	hint_stage = ""
	hint_tier = 0
	changed.emit()
	inventory_changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# --- 設定と言語 ----------------------------------------------------------------

func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("general", "locale", locale)
	cfg.save(SETTINGS_PATH)
	changed.emit()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var locale := "ja"
	if cfg.load(SETTINGS_PATH) == OK:
		locale = String(cfg.get_value("general", "locale", "ja"))
	elif not OS.get_locale_language() == "ja":
		locale = "en"
	TranslationServer.set_locale(locale)


## i18n/text.csv(keys,ja,en)を読み込んで TranslationServer に登録する。
## CSV はインポートせず("keep")実行時に読むので、エディタを開かなくても動く。
## 文中の "\n" は改行、"|" はページ区切り(会話ウィンドウでクリック送り)。
func _load_translations() -> void:
	var f := FileAccess.open(TEXT_CSV, FileAccess.READ)
	if f == null:
		push_error("翻訳ファイルが開けません: %s" % TEXT_CSV)
		return
	var header := f.get_csv_line()
	var translations: Array[Translation] = []
	for i in range(1, header.size()):
		var t := Translation.new()
		t.locale = header[i].strip_edges()
		translations.append(t)
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0].is_empty() or row[0].begins_with("#"):
			continue
		for i in range(1, header.size()):
			if i < row.size() and not row[i].is_empty():
				translations[i - 1].add_message(row[0], row[i].replace("\\n", "\n"))
	for t in translations:
		TranslationServer.add_translation(t)
