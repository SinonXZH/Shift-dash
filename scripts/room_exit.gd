@tool
extends Node2D
@export var size := Vector2(68, 116):
	set(value):
		size = value
		queue_redraw()
var unlocked := false:
	set(value):
		unlocked = value
		queue_redraw()

func contains(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(to_local(point))

func _draw() -> void:
	var color := Color("62f5e8") if unlocked else Color("344052")
	draw_rect(Rect2(Vector2.ZERO, size), Color(color, 0.15))
	draw_rect(Rect2(Vector2.ZERO, size), color, false, 3)
	var center := size * 0.5
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), color, 4)
	draw_line(center + Vector2(3, -15), center + Vector2(18, 0), color, 4)
	draw_line(center + Vector2(3, 15), center + Vector2(18, 0), color, 4)
