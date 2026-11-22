extends Control
## ゲーム本編。部屋の読み込み、クリックへの反応(Story.RULES の実行)、
## 謎の表示、ポッポのヒント、章の終わりを受け持つ。

const FADE_TIME := 0.35

var room_node: Room
var puzzle_node: PuzzleBase
var busy := false

var _room_layer: Control
var _puzzle_layer: Control
var _dialogue: DialogueBox
var _inventory: InventoryBar
var _room_label: Label
var _use_label: Label
var _hint_button: Button
var _fade: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_room_layer = _full_rect_layer("RoomLayer")
	_build_hud()
	_puzzle_layer = _full_rect_layer("PuzzleLayer")
	_dialogue = DialogueBox.new()
	_dialogue.name = "Dialogue"
	add_child(_dialogue)
	_fade = ColorRect.new()
	_fade.color = Color(0.1, 0.08, 0.06, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	GameState.changed.connect(_refresh_hud)
	_load_room(GameState.room)
	if not GameState.has_flag("intro_done"):
		run_actions([["say", "INTRO", ""], ["say", "INTRO_MOKO", "moko"], ["set", "intro_done"]])


func _full_rect_layer(n: String) -> Control:
	var c := Control.new()
	c.name = n
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _build_hud() -> void:
	var hud := _full_rect_layer("HUD")
	_room_label = Label.new()
	_room_label.position = Vector2(40, 28)
	_room_label.add_theme_font_size_override("font_size", 40)
	_room_label.add_theme_color_override("font_color", Color(0.35, 0.27, 0.2))
	_room_label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	_room_label.add_theme_constant_override("outline_size", 10)
	hud.add_child(_room_label)

	_inventory = InventoryBar.new()
	_inventory.name = "Inventory"
	_inventory.position = Vector2(40, 96)
	_inventory.selection_changed.connect(func(_i): _refresh_hud())
	hud.add_child(_inventory)

	_use_label = Label.new()
	_use_label.position = Vector2(40, 192)
	_use_label.add_theme_font_size_override("font_size", 26)
	_use_label.add_theme_color_override("font_color", Color(0.72, 0.42, 0.35))
	hud.add_child(_use_label)

	_hint_button = Button.new()
	_hint_button.name = "HintButton"
	_hint_button.focus_mode = Control.FOCUS_NONE
	_hint_button.position = Vector2(1560, 28)
	_hint_button.custom_minimum_size = Vector2(320, 84)
	_hint_button.add_theme_font_size_override("font_size", 30)
	_hint_button.pressed.connect(show_hint)
	hud.add_child(_hint_button)

	var menu := Button.new()
	menu.focus_mode = Control.FOCUS_NONE
	menu.position = Vector2(1560, 128)
	menu.custom_minimum_size = Vector2(320, 64)
	menu.add_theme_font_size_override("font_size", 24)
	menu.text = tr("UI_TO_TITLE")
	menu.pressed.connect(_to_title)
	hud.add_child(menu)
	_refresh_hud()


func _refresh_hud() -> void:
	if room_node:
		_room_label.text = tr(room_node.name_key)
	_hint_button.text = tr("UI_HINT")
	if _inventory.selected.is_empty():
		_use_label.text = ""
	else:
		_use_label.text = tr("UI_USING").format({"item": tr(Story.ITEMS.get(_inventory.selected, ""))})


# --- 部屋 -----------------------------------------------------------------------

func _load_room(room_id: String) -> void:
	if not Story.ROOMS.has(room_id):
		push_error("知らない部屋: %s" % room_id)
		room_id = "kitchen"
	if room_node:
		_room_layer.remove_child(room_node)
		room_node.queue_free()
	room_node = (load(Story.ROOMS[room_id]) as PackedScene).instantiate() as Room
	room_node.hotspot_pressed.connect(on_hotspot)
	_room_layer.add_child(room_node)
	GameState.room = room_id
	_refresh_hud()


func change_room(room_id: String) -> void:
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await t.finished
	_load_room(room_id)
	GameState.save_game()  # オートセーブは部屋移動ごと
	t = create_tween()
	t.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await t.finished


# --- クリックとルール -------------------------------------------------------------

func on_hotspot(hotspot_id: String) -> void:
	if busy or puzzle_node != null or _dialogue.is_active():
		return
	var rule := find_rule(hotspot_id, _inventory.selected)
	if rule.is_empty():
		if not _inventory.selected.is_empty():
			var item := _inventory.selected
			_inventory.clear_selection()
			await run_actions([["say_fmt", "CANT_USE", "moko", {"item": tr(Story.ITEMS.get(item, item))}]])
		return
	_inventory.clear_selection()
	await run_actions(rule.get("do", []))


## 選択中の持ち物(なければ "")を踏まえて、最初に条件を満たすルールを返す
func find_rule(rule_id: String, selected_item: String = "") -> Dictionary:
	for rule in Story.RULES.get(rule_id, []):
		if rule.has("use"):
			if rule["use"] != selected_item:
				continue
		elif not selected_item.is_empty():
			continue
		if GameState.check_all(rule.get("if", [])):
			return rule
	return {}


func run_actions(actions: Array) -> void:
	busy = true
	for a in actions:
		match String(a[0]):
			"say":
				await _dialogue.show_key(a[1], a[2] if a.size() > 2 else "")
			"say_fmt":
				await _dialogue.show_key(a[1], a[2], a[3])
			"set":
				GameState.set_flag(a[1])
			"clear":
				GameState.set_flag(a[1], false)
			"give":
				GameState.add_item(a[1])
				await _dialogue.show_key("GOT_ITEM", "", {"item": tr(Story.ITEMS.get(a[1], a[1]))})
			"take":
				GameState.remove_item(a[1])
			"goto":
				await change_room(a[1])
			"puzzle":
				open_puzzle(a[1])
			"end_chapter":
				await _end_chapter(int(a[1]))
			_:
				push_error("知らないアクション: %s" % a[0])
	busy = false


# --- 謎 ---------------------------------------------------------------------------

func open_puzzle(puzzle_id: String) -> void:
	if puzzle_node != null:
		return
	puzzle_node = (load(Story.PUZZLES[puzzle_id]) as PackedScene).instantiate() as PuzzleBase
	puzzle_node.solved.connect(_on_puzzle_solved.bind(puzzle_id))
	puzzle_node.closed.connect(close_puzzle)
	_puzzle_layer.add_child(puzzle_node)


func close_puzzle() -> void:
	if puzzle_node:
		puzzle_node.queue_free()
		puzzle_node = null


func _on_puzzle_solved(puzzle_id: String) -> void:
	busy = true
	await get_tree().create_timer(1.0).timeout
	close_puzzle()
	var rule := find_rule("solved:" + puzzle_id)
	await run_actions(rule.get("do", []))
	GameState.save_game()


# --- ヒント -----------------------------------------------------------------------

func current_hint_stage() -> Dictionary:
	for stage in Story.HINTS:
		if not GameState.has_flag(stage["until"]):
			return stage
	return {}


func show_hint() -> void:
	if busy or _dialogue.is_active():
		return
	var stage := current_hint_stage()
	if stage.is_empty():
		await run_actions([["say", "HINT_NONE", "poppo"]])
		return
	if GameState.hint_stage != stage["until"]:
		GameState.hint_stage = stage["until"]
		GameState.hint_tier = 0
	var keys: Array = stage["keys"]
	var key: String = keys[mini(GameState.hint_tier, keys.size() - 1)]
	GameState.hint_tier += 1
	await run_actions([["say", key, "poppo"]])


# --- 章の終わり -------------------------------------------------------------------

func _end_chapter(chapter: int) -> void:
	var card := ColorRect.new()
	card.color = Color(0.16, 0.12, 0.1, 0.0)
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(card)
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.84))
	label.add_theme_constant_override("line_spacing", 24)
	label.text = tr("CHAPTER_END_%d" % chapter)
	label.modulate.a = 0.0
	card.add_child(label)
	var t := create_tween()
	t.tween_property(card, "color:a", 1.0, 1.2)
	t.tween_property(label, "modulate:a", 1.0, 1.0)
	await t.finished
	GameState.chapter = chapter + 1
	GameState.set_flag("chapter%d_clear" % chapter)
	GameState.save_game()
	move_child(_dialogue, -1)
	await _dialogue.show_key("DEMO_END")
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _to_title() -> void:
	if busy:
		return
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if puzzle_node and not busy:
			close_puzzle()
		elif not _inventory.selected.is_empty():
			_inventory.clear_selection()
