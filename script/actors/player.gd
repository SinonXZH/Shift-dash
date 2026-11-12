class_name Player
extends CharacterBody2D

@export var move_speed := 240.0

@export var dash_controller: DashController


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		dash_controller.try_dash(get_global_mouse_position() - global_position)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if dash_controller.is_dashing:
		var dash_velocity := dash_controller.get_dash_velocity(delta)
		velocity = dash_velocity
		move_and_slide()
		for index in range(get_slide_collision_count()):
			if get_slide_collision(index).get_normal().dot(dash_velocity) < 0.0:
				dash_controller.end_dash()
				break
		dash_controller.advance(delta)
		if not dash_controller.is_dashing:
			velocity = Vector2.ZERO
	else:
		velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * move_speed
		move_and_slide()


func reset(spawn_position: Vector2) -> void:
	dash_controller.reset()
	velocity = Vector2.ZERO
	global_position = spawn_position
