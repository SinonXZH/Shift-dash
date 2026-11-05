@tool
extends StaticBody2D
## Collision children are the source of truth. Edit their shapes in the 2D editor.
@export var color := Color("47617d"):
	set(value):
		color = value
		queue_redraw()

var _pending_size: Variant = null
# Compatibility for existing scenes/code that used obstacle.size.
# New layouts should edit CollisionShape2D or CollisionPolygon2D directly.
var size: Vector2:
	get:
		var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collider != null and collider.shape is RectangleShape2D:
			return collider.shape.size
		return Vector2(96, 96) if _pending_size == null else _pending_size
	set(value):
		_pending_size = Vector2(maxf(8, value.x), maxf(8, value.y))
		if is_node_ready():
			apply_legacy_size()

func _ready() -> void:
	if _pending_size != null:
		apply_legacy_size()

func apply_legacy_size() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider != null:
		var rectangle := RectangleShape2D.new()
		rectangle.size = _pending_size
		collider.set_deferred("shape", rectangle)
	queue_redraw()

func _process(_delta: float) -> void:
	# Also reflects live vertex edits and child transforms while the game runs.
	queue_redraw()

func _draw() -> void:
	for child in get_children():
		if child is CollisionShape2D and not child.disabled and child.shape != null:
			draw_set_transform_matrix(child.transform)
			child.shape.draw(get_canvas_item(), color)
		elif child is CollisionPolygon2D and not child.disabled and child.polygon.size() >= 3:
			var polygon: PackedVector2Array = child.polygon
			# Invalid/self-intersecting edits must not spam draw errors in the editor.
			if Geometry2D.triangulate_polygon(polygon).is_empty():
				continue
			draw_set_transform_matrix(child.transform)
			draw_colored_polygon(polygon, color)
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, color.lightened(0.3), 2, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
