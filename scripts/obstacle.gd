@tool
extends StaticBody2D
## Resize using Size; collision and editor drawing update together.
@export var size := Vector2(96, 96):
	set(value):
		size = Vector2(maxf(8, value.x), maxf(8, value.y))
		update_shape()
@export var color := Color("47617d"):
	set(value):
		color = value
		queue_redraw()

func _ready() -> void:
	update_shape()

func update_shape() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	$CollisionShape2D.set_deferred("shape", rectangle)

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), color)
	draw_rect(Rect2(-size * 0.5, size), color.lightened(0.3), false, 3)
	draw_line(-size * 0.5, size * 0.5, Color(color.lightened(0.2), 0.4), 2)
