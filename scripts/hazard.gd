@tool
extends Area2D
@export var size := Vector2(96, 48):
	set(value):
		size = Vector2(maxf(8, value.x), maxf(8, value.y))
		update_shape()
@export_range(1, 99, 1) var damage := 1
## By default touching this hazard also hurts during a dash.
@export var dash_can_pass_safely := false

func _ready() -> void:
	update_shape()
	if not Engine.is_editor_hint():
		add_to_group("room_hazards")

func update_shape() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	$CollisionShape2D.set_deferred("shape", rectangle)

func touches_path(start: Vector2, end: Vector2, radius: float) -> bool:
	# Sweep the player's footprint so fast dashes cannot skip a narrow hazard.
	var local_radius := radius / maxf(0.001, minf(global_scale.abs().x, global_scale.abs().y))
	var rect := Rect2(-size * 0.5, size).grow(local_radius)
	var origin := to_local(start)
	var direction := to_local(end) - origin
	var entry := 0.0
	var exit := 1.0
	for axis in range(2):
		if absf(direction[axis]) < 0.00001:
			if origin[axis] < rect.position[axis] or origin[axis] > rect.end[axis]:
				return false
		else:
			var a: float = (rect.position[axis] - origin[axis]) / direction[axis]
			var b: float = (rect.end[axis] - origin[axis]) / direction[axis]
			entry = maxf(entry, minf(a, b))
			exit = minf(exit, maxf(a, b))
			if entry > exit:
				return false
	return true

func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color("60283c"))
	draw_rect(rect, Color("ff567d"), false, 3)
	for x in range(0, int(size.x), 20):
		var center := Vector2(-size.x * 0.5 + x + 10, 0)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-7, size.y * 0.3), center + Vector2(0, -size.y * 0.3), center + Vector2(7, size.y * 0.3)]), Color("ff7894"))
