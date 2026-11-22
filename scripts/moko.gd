@tool
class_name Moko
extends Control
## 主人公モコの仮の姿(丸いシルエットに点の目)。ゆっくり上下にゆれる。

## 立ち絵。設定されていれば仮の図形の代わりに描く
@export var texture: Texture2D

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if texture:
		# 息をしているように、ほんの少し伸び縮みさせる
		var s := 1.0 + sin(_t * 2.0) * 0.012
		var fit := minf(size.x / texture.get_width(), size.y / texture.get_height())
		var tsz := Vector2(texture.get_width(), texture.get_height()) * fit * Vector2(1.0 / s, s)
		draw_texture_rect(texture, Rect2(Vector2((size.x - tsz.x) * 0.5, size.y - tsz.y), tsz), false)
		return
	var line := Color(0.35, 0.27, 0.2)
	var wool := Color(1, 1, 1)
	var c := size * 0.5 + Vector2(0, sin(_t * 2.0) * 4.0)
	var r := minf(size.x, size.y) * 0.22
	# 足
	for dx in [-0.45, -0.15, 0.15, 0.45]:
		draw_rect(Rect2(c + Vector2(dx * r * 2.2 - 8, r * 1.1), Vector2(16, r * 0.9)), line)
	# もこもこの体
	var puffs := [Vector2(-1.1, 0.2), Vector2(-0.6, -0.5), Vector2(0.2, -0.7), Vector2(0.9, -0.3),
		Vector2(1.1, 0.4), Vector2(0.5, 0.9), Vector2(-0.4, 0.9), Vector2(0, 0.1)]
	for p in puffs:
		draw_circle(c + p * r, r * 0.75, line)
	for p in puffs:
		draw_circle(c + p * r, r * 0.75 - 4.0, wool)
	# 顔
	var face := c + Vector2(-r * 1.15, -r * 0.1)
	draw_set_transform(face, 0.0, Vector2(1.0, 1.25))
	draw_circle(Vector2.ZERO, r * 0.55, line)
	draw_set_transform(Vector2.ZERO)
	draw_circle(face + Vector2(-r * 0.2, -r * 0.1), 5.0, Color.WHITE)
	draw_circle(face + Vector2(r * 0.18, -r * 0.1), 5.0, Color.WHITE)
	# 耳
	draw_circle(face + Vector2(-r * 0.6, -r * 0.45), r * 0.18, line)
	draw_circle(face + Vector2(r * 0.55, -r * 0.5), r * 0.18, line)
