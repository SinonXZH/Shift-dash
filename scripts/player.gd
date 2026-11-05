@tool
extends CharacterBody2D
signal confirmed(perfect: bool)
const PLAYER_RADIUS := 13.0
const CYAN := Color("62f5e8")
const GOLD := Color("ffd078")
const DashBehavior = preload("res://scripts/dash_behavior.gd")
var rhythm: RefCounted
var tuning: Dictionary = {}
var dash_direction := Vector2.RIGHT
var dash_left := 0.0
var active_dash_speed := 1500.0
var active_dash_duration := 0.16
var dash_protection_left := 0.0
var cooldown := 0.0
var invulnerability := 0.0
var active_cooldown := 0.35
var empowered_dash := false
var dash_color := CYAN
var success_ring_left := 0.0
var last_rewarded_beat := -INF
var rhythm_feedback := ""
var rhythm_feedback_left := 0.0
var rhythm_feedback_color := CYAN
var elapsed := 0.0
var trails: Array[Dictionary] = []
var aiming := false
var dash_hits: Array[Node] = []
var contact_slowdown := false

func reset_at(location: Vector2) -> void:
	global_position = location
	dash_left = 0.0
	dash_protection_left = 0.0
	cooldown = 0.0
	invulnerability = 1.0
	empowered_dash = false
	success_ring_left = 0.0
	last_rewarded_beat = -INF
	rhythm_feedback_left = 0.0
	trails.clear()
	dash_hits.clear()
	contact_slowdown = false
	queue_redraw()

func try_dash() -> void:
	if cooldown > 0.0 or dash_left > 0.0:
		return
	var error: float = rhythm.timing_error()
	var beat: float = rhythm.nearest_dash_beat()
	var result := DashBehavior.evaluate(int(tuning.get("dash_mode", 2)), error, rhythm.perfect_window, rhythm.good_window, beat != last_rewarded_beat)
	rhythm_feedback = result["label"]
	rhythm_feedback_left = tuning["feedback_duration"]
	if not result["allowed"]:
		empowered_dash = false
		success_ring_left = 0.0
		rhythm_feedback_color = Color("9baec5")
		return
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 1.0:
		dash_direction = aim.normalized()
	empowered_dash = result["empowered"]
	contact_slowdown = int(tuning.get("dash_mode", 2)) == DashBehavior.Mode.CONTACT_SLOWDOWN and not result["perfect"]
	var speed_factor: float = tuning["onbeat_speed"] if empowered_dash else 1.0
	active_dash_speed = tuning["dash_speed"] * speed_factor
	active_dash_duration = tuning["dash_duration"] / speed_factor
	dash_left = active_dash_duration
	# Equal distance and equal protection time; the reward is a faster arrival.
	dash_protection_left = tuning["dash_duration"]
	active_cooldown = tuning["onbeat_cooldown"] if empowered_dash else tuning["dash_cooldown"]
	cooldown = active_cooldown
	if result["perfect"]:
		rhythm_feedback_color = GOLD
	elif result["confirmed"]:
		rhythm_feedback_color = CYAN
	else:
		rhythm_feedback_color = Color("9baec5")
	dash_color = rhythm_feedback_color if empowered_dash else CYAN
	if result["confirmed"]:
		last_rewarded_beat = beat
		confirmed.emit(result["perfect"])
	if empowered_dash:
		success_ring_left = 0.22

func step(delta: float, bounds: Rect2, enemies: Array = []) -> void:
	dash_hits.clear()
	elapsed += delta
	rhythm_feedback_left = maxf(0.0, rhythm_feedback_left - delta)
	success_ring_left = maxf(0.0, success_ring_left - delta)
	cooldown = maxf(0.0, cooldown - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	dash_protection_left = maxf(0.0, dash_protection_left - delta)
	var previous := global_position
	var is_dashing := dash_left > 0.0
	if is_dashing:
		advance_dash(minf(delta, dash_left), bounds, enemies)
		dash_left = maxf(0.0, dash_left - delta)
	elif not tuning["disable_movement"]:
		var movement := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		global_position += movement.normalized() * tuning["move_speed"] * delta
	global_position = global_position.clamp(bounds.position + Vector2.ONE * PLAYER_RADIUS, bounds.end - Vector2.ONE * PLAYER_RADIUS)
	if not is_dashing:
		var displacement := global_position - previous
		global_position = previous
		var collision := move_and_collide(displacement)
		if collision != null:
			move_and_collide(collision.get_remainder().slide(collision.get_normal()))
	if is_dashing:
		var lifetime := 0.36 if empowered_dash else 0.18
		trails.append({"position": previous, "end": global_position, "life": lifetime, "duration": lifetime, "strong": empowered_dash, "color": dash_color})
	for index in range(trails.size() - 1, -1, -1):
		trails[index]["life"] -= delta
		if trails[index]["life"] <= 0:
			trails.remove_at(index)
	queue_redraw()

func advance_dash(duration: float, bounds: Rect2, enemies: Array) -> void:
	# Short spatial steps apply impact slowdown before crossing the next enemy,
	# even if a low frame rate puts several contacts in one physics tick.
	var remaining := duration
	while remaining > 0.000001:
		var slice := minf(remaining, 8.0 / active_dash_speed)
		var start := global_position
		var target := (start + dash_direction * active_dash_speed * slice).clamp(bounds.position + Vector2.ONE * PLAYER_RADIUS, bounds.end - Vector2.ONE * PLAYER_RADIUS)
		var collision := move_and_collide(target - start)
		for enemy in enemies:
			if dash_hits.has(enemy):
				continue
			var nearest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, global_position)
			if enemy.global_position.distance_to(nearest) < tuning["hit_radius"]:
				dash_hits.append(enemy)
				if contact_slowdown:
					active_dash_speed = maxf(tuning["dash_speed"] * 0.15, active_dash_speed * tuning.get("enemy_hit_speed_factor", 0.45))
		remaining -= slice
		if collision != null or global_position.is_equal_approx(start):
			dash_left = 0.0
			break

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, PLAYER_RADIUS, CYAN)
		draw_arc(Vector2.ZERO, 27, 0, TAU, 48, Color(CYAN, 0.5), 2)
		return
	for trail in trails:
		var alpha: float = trail["life"] / trail["duration"]
		var color: Color = trail["color"]
		if trail["strong"]:
			draw_line(to_local(trail["position"]), to_local(trail["end"]), Color(color, alpha * 0.16), 28.0, true)
			draw_line(to_local(trail["position"]), to_local(trail["end"]), Color(color, alpha * 0.6), 10.0, true)
			draw_line(to_local(trail["position"]), to_local(trail["end"]), Color(Color.WHITE, alpha * 0.7), 3.0, true)
		else:
			draw_circle(to_local(trail["position"]), PLAYER_RADIUS, Color(CYAN, alpha * 0.35))
	var aim := (get_global_mouse_position() - global_position).normalized()
	if aiming:
		draw_line(Vector2.ZERO + aim * 22, Vector2.ZERO + aim * 72, Color(CYAN, 0.5), 2.0)
	var player_color := CYAN
	if invulnerability > 0 and sin(elapsed * 35.0) > 0:
		player_color = Color.WHITE
	draw_circle(Vector2.ZERO, PLAYER_RADIUS + 5, Color(CYAN, 0.12))
	if empowered_dash and dash_left > 0.0:
		# Stretch along the actual chosen direction, without changing collision size.
		var progress := 1.0 - dash_left / active_dash_duration
		var stretch := 1.0 + 1.4 * sin(PI * progress)
		var outline := PackedVector2Array()
		for index in range(32):
			var angle := TAU * float(index) / 32.0
			var local := Vector2(cos(angle) * PLAYER_RADIUS * stretch, sin(angle) * PLAYER_RADIUS / sqrt(stretch))
			outline.append(Vector2.ZERO + local.rotated(dash_direction.angle()))
		draw_colored_polygon(outline, dash_color)
		draw_line(Vector2.ZERO - dash_direction * 24, Vector2.ZERO + dash_direction * 20, Color.WHITE, 3.0, true)
	else:
		draw_circle(Vector2.ZERO, PLAYER_RADIUS, player_color)
		draw_circle(Vector2.ZERO + aim * 6, 4.0, Color("0c1729"))
	if rhythm != null and not tuning.is_empty():
		draw_rhythm_rings()

func draw_rhythm_rings() -> void:
	# Rhythm uses full rings; cooldown is conveyed by the small bar underneath.
	var offsets: Array[float] = rhythm.upcoming_offsets()
	var flash := 0.0
	for offset in offsets:
		flash = maxf(flash, 1.0 - absf(offset) / rhythm.good_window)
	draw_arc(Vector2.ZERO, 27.0, 0, TAU, 72, Color(CYAN, 0.45), 2.0, true)
	for offset in offsets:
		if offset < 0.0 or offset > rhythm.preview_seconds:
			continue
		var progress := clampf(offset / rhythm.preview_seconds, 0.0, 1.0)
		var radius := lerpf(27.0, tuning["ring_radius"], progress)
		var ring_color := Color(CYAN, lerpf(1.0, 0.18, progress))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 72, ring_color, 2.5, true)
	if flash > 0:
		draw_arc(Vector2.ZERO, 27.0, 0, TAU, 72, Color(GOLD, flash), 4.0, true)
	if success_ring_left > 0:
		var strength := success_ring_left / 0.22
		draw_arc(Vector2.ZERO, lerpf(18.0, 45.0, strength), 0, TAU, 72, Color(dash_color, strength), 3.5, true)
	var bar_start := Vector2.ZERO + Vector2(-14, 34)
	draw_line(bar_start, bar_start + Vector2(28, 0), Color("344052"), 3.0)
	draw_line(bar_start, bar_start + Vector2(28 * clampf(1.0 - cooldown / active_cooldown, 0.0, 1.0), 0), CYAN, 3.0)
