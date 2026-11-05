extends SceneTree
func _initialize() -> void:
	create_timer(5.0).timeout.connect(func(): quit(1))
	call_deferred("check_shapes")
func point_hits(at: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = at
	query.collision_mask = 1
	return not root.get_world_2d().direct_space_state.intersect_point(query).is_empty()
func check_shapes() -> void:
	var scene = load("res://scenes/props/obstacle.tscn")
	var first = scene.instantiate()
	var second = scene.instantiate()
	root.add_child(first)
	root.add_child(second)
	first.position = Vector2(200, 200)
	second.position = Vector2(400, 200)
	assert(first.get_node("CollisionShape2D").shape != second.get_node("CollisionShape2D").shape)
	first.get_node("CollisionShape2D").shape.size = Vector2(80, 160)
	assert(second.get_node("CollisionShape2D").shape.size == Vector2(96, 96))
	var circle := CircleShape2D.new()
	circle.radius = 30
	first.get_node("CollisionShape2D").shape = circle
	var polygon = load("res://scenes/props/polygon_obstacle.tscn").instantiate()
	root.add_child(polygon)
	polygon.position = Vector2(600, 200)
	await physics_frame
	await physics_frame
	assert(first.get_node("CollisionShape2D").shape == circle)
	assert(point_hits(Vector2(200, 200)))
	assert(not point_hits(Vector2(235, 200)))
	assert(point_hits(Vector2(568, 224)))
	assert(point_hits(Vector2(632, 176)))
	assert(not point_hits(Vector2(632, 224)))
	polygon.get_node("CollisionPolygon2D").polygon = PackedVector2Array([Vector2(-20,-20), Vector2(20,-20), Vector2(0,20)])
	await physics_frame
	await physics_frame
	assert(point_hits(Vector2(600, 200)))
	assert(not point_hits(Vector2(568, 224)))
	first.size = Vector2(70, 90)
	await physics_frame
	await physics_frame
	assert(first.get_node("CollisionShape2D").shape is RectangleShape2D)
	assert(first.size == Vector2(70, 90))
	print("PASS: primitive shape replacement, isolated resources, concave polygon notch, edited vertices, legacy rectangle size")
	first.queue_free()
	second.queue_free()
	polygon.queue_free()
	await process_frame
	quit()
