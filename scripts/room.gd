@tool
class_name Room
extends Control
## 1部屋 = 1シーン。背景(仮)を章ごとの色で塗り、子の Hotspot のクリックを中継する。

signal hotspot_pressed(hotspot_id: String)

@export var room_id: String = ""
@export var name_key: String = ""
## 章ごとの壁の色(1章, 2章, 3章, 4章)。足りなければ最後の色を使う
@export var wall_colors: Array[Color] = [Color(0.99, 0.94, 0.86)]
@export var floor_color: Color = Color(0.86, 0.72, 0.55)
@export var floor_height: float = 300.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if Engine.is_editor_hint():
		return
	for h in find_children("*", "Hotspot", true, false):
		(h as Hotspot).pressed.connect(func(id: String): hotspot_pressed.emit(id))
	GameState.changed.connect(queue_redraw)


func _chapter() -> int:
	return 1 if Engine.is_editor_hint() else GameState.chapter


func _draw() -> void:
	var idx := clampi(_chapter() - 1, 0, max(wall_colors.size() - 1, 0))
	var wall: Color = wall_colors[idx] if wall_colors.size() > 0 else Color.WHITE
	var w := 1920.0
	var h := 1080.0
	draw_rect(Rect2(0, 0, w, h - floor_height), wall)
	# 壁紙のしま模様(絵本っぽさの仮表現)
	for x in range(0, int(w), 120):
		draw_rect(Rect2(x, 0, 60, h - floor_height), wall.darkened(0.03))
	draw_rect(Rect2(0, h - floor_height, w, floor_height), floor_color)
	draw_line(Vector2(0, h - floor_height), Vector2(w, h - floor_height), floor_color.darkened(0.3), 6.0)
