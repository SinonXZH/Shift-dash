@tool
extends CharacterBody2D
signal fired(location: Vector2, velocity: Vector2)
@export_enum("Chaser", "Shooter") var kind: int = 0:
	set(value):
		kind = value
		queue_redraw()
@export_range(0.0, 4.0, 0.1) var speed_multiplier := 1.0
## Disable locomotion only; attacks, damage and room-clear participation remain active.
@export var movement_disabled := false
@export_range(0.1, 5.0, 0.1) var initial_fire_delay := 1.2
var fire_left := 1.2

func _ready() -> void:
	fire_left = initial_fire_delay

func step(delta: float, target: Vector2, bounds: Rect2, tuning: Dictionary, difficulty: int) -> void:
	var offset := target - global_position
	var speed: float = (tuning["enemy_speed"] + difficulty * tuning["enemy_speed_growth"]) * speed_multiplier
	if kind == 1:
		speed *= 0.5 if offset.length() > 260.0 else -0.25
	if not movement_disabled:
		var target_position := (global_position + offset.normalized() * speed * delta).clamp(bounds.position + Vector2.ONE * 20, bounds.end - Vector2.ONE * 20)
		move_and_collide(target_position - global_position)
	fire_left -= delta
	if kind == 1 and fire_left <= 0:
		fire_left = maxf(0.1, tuning["fire_interval"] - difficulty * tuning["fire_reduction"])
		fired.emit(global_position, offset.normalized() * (tuning["bullet_speed"] + difficulty * tuning["bullet_growth"]))

func _draw() -> void:
	if kind == 1:
		draw_rect(Rect2(-16, -16, 32, 32), Color("ffd078"), false, 3)
		draw_circle(Vector2.ZERO, 5, Color("ffd078"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -19), Vector2(18, 14), Vector2(-18, 14)]), Color("ff567d"))
