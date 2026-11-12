class_name CameraZone
extends Area2D

var player: Player
@export var phantom_camera: PhantomCamera2D
@export var active_priority := 2
@export var inactive_priority := 0


func _ready() -> void:
	_set_active(false)


func configure(target: Player) -> void:
	player = target
	if not is_instance_valid(phantom_camera):
		push_warning("CameraZone requires a phantom_camera reference: %s" % get_path())
		return
	if phantom_camera.follow_mode != PhantomCamera2D.FollowMode.NONE:
		phantom_camera.set_follow_target(player)
	reset_trigger()


func reset_trigger() -> void:
	_set_active(false)
	# Spawn/teleport overlaps are refreshed by the physics server, not immediately.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_inside_tree() and is_instance_valid(player):
		_set_active(overlaps_body(player))


func _on_body_entered(body: Node2D) -> void:
	if body != player or not is_instance_valid(player):
		return
	_set_active(true)


func _on_body_exited(body: Node2D) -> void:
	if body != player or not is_instance_valid(player):
		return
	_set_active(false)


func _set_active(value: bool) -> void:
	if is_instance_valid(phantom_camera):
		phantom_camera.set_priority(active_priority if value else inactive_priority)
