class_name InventoryBar
extends HBoxContainer
## 持ち物の欄。押すと「選択中」になり、その状態で部屋の場所をクリックすると「使う」。

signal selection_changed(item: String)

var selected: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	GameState.inventory_changed.connect(_rebuild)
	GameState.changed.connect(_refresh_labels)
	_rebuild()


func clear_selection() -> void:
	selected = ""
	_refresh_labels()
	selection_changed.emit(selected)


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if not GameState.has_item(selected):
		selected = ""
	for item in GameState.inventory:
		var b := Button.new()
		b.set_meta("item", item)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(220, 84)
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(_on_pressed.bind(item))
		add_child(b)
	_refresh_labels()


func _refresh_labels() -> void:
	for b in get_children():
		var item := String(b.get_meta("item", ""))
		b.text = tr(Story.ITEMS.get(item, item))
		b.set_pressed_no_signal(item == selected)


func _on_pressed(item: String) -> void:
	selected = "" if selected == item else item
	_refresh_labels()
	selection_changed.emit(selected)
