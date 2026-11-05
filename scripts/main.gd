extends Node2D
const RhythmGuide = preload("res://scripts/rhythm_guide.gd")
const CYAN := Color("62f5e8")
const PINK := Color("ff567d")
const GOLD := Color("ffd078")
const PLAYER_RADIUS := 13.0
@export var room_scenes: Array[PackedScene] = []
@onready var player: Node2D = $Player
@onready var ui: CanvasLayer = $GameUI
@onready var settings: CanvasLayer = $DebugSettings
@onready var beat_audio: AudioStreamPlayer = $BeatAudio
@onready var confirm_audio: AudioStreamPlayer = $DashConfirmAudio
var current_room: Node2D
var rhythm := RhythmGuide.new()
var tuning: Dictionary = {}
var room := 1
var health := 3
var run_max_health := 3
var elapsed := 0.0
var mode := "ready"
var mode_before_settings := "ready"
var enemies: Array[Node] = []
var bullets: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	settings.initialize(ui.get_node("HUD").get_theme_default_font())
	settings.applied.connect(apply_tuning)
	settings.closed.connect(close_settings)
	ui.start_requested.connect(start_run)
	ui.settings_requested.connect(open_settings)
	player.rhythm = rhythm
	player.confirmed.connect(confirm_audio.confirm)
	apply_tuning(settings.values.duplicate())
	current_room = $Rooms.get_child(0) if $Rooms.get_child_count() > 0 else null
	show_overlay("SHIFT DASH", "WASD / Arrow keys: move. Mouse: aim.\nShift / Right click: dash. Perfect timing grants a burst.\nDash when the shrinking ring meets the inner ring.\nClear all enemies, then enter the glowing exit.\n\nPress ENTER to start")
	update_ui()

func show_overlay(heading: String, body: String) -> void:
	ui.show_overlay(heading, body)

func start_run() -> void:
	room = 1
	health = int(tuning["max_health"])
	run_max_health = health
	elapsed = 0.0
	mode = "playing"
	ui.overlay.hide()
	spawn_room()

func spawn_room() -> void:
	if room_scenes.is_empty():
		push_error("Assign at least one room in the main scene Room Scenes array.")
		return
	for child in $Rooms.get_children():
		$Rooms.remove_child(child)
		child.queue_free()
	current_room = room_scenes[room - 1].instantiate()
	$Rooms.add_child(current_room)
	enemies.assign(current_room.get_node("Enemies").get_children())
	for enemy in enemies:
		enemy.fired.connect(add_bullet)
	confirm_audio.stop()
	confirm_audio.stream_paused = mode != "playing"
	rhythm.reset(current_room.rhythm_section)
	player.reset_at(current_room.get_node("PlayerSpawn").global_position)
	start_beat_audio()
	bullets.clear()
	sparks.clear()
	current_room.get_node("Exit").unlocked = enemies.is_empty()

func add_bullet(location: Vector2, velocity: Vector2) -> void:
	bullets.append({"position": location, "velocity": velocity})

func try_dash() -> void:
	if mode == "playing":
		sync_rhythm_audio()
		player.try_dash()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or (event.keycode == KEY_ESCAPE and mode == "settings"):
			if mode == "settings":
				close_settings()
			else:
				open_settings()
			get_viewport().set_input_as_handled()

func open_settings() -> void:
	if mode == "settings":
		return
	mode_before_settings = mode
	mode = "settings"
	beat_audio.stream_paused = true
	confirm_audio.stream_paused = true
	settings.open()

func close_settings() -> void:
	settings.screen.hide()
	mode = mode_before_settings
	beat_audio.stream_paused = mode != "playing"
	confirm_audio.stream_paused = mode != "playing"

func apply_tuning(values: Dictionary) -> void:
	var reset_clock: bool = tuning.is_empty() or rhythm.bpm != values["bpm"] or rhythm.count_in_beats != values["count_in"] or rhythm.preview_seconds != values["preview"]
	tuning = values.duplicate()
	player.tuning = tuning
	rhythm.bpm = tuning["bpm"]
	rhythm.count_in_beats = tuning["count_in"]
	rhythm.preview_seconds = tuning["preview"]
	rhythm.perfect_window = tuning["perfect"]
	rhythm.good_window = tuning["good"]
	beat_audio.volume_db = linear_to_db(maxf(0.0001, tuning["audio_volume"] / 100.0))
	confirm_audio.volume_db = linear_to_db(maxf(0.0001, tuning["confirm_volume"] / 100.0))
	beat_audio.sync_offset = tuning["audio_offset"] / 1000.0
	if reset_clock:
		player.last_rewarded_beat = -INF
		rhythm.reset(current_room.rhythm_section if current_room != null else 0)
		if beat_audio.stream != null:
			start_beat_audio()
	player.cooldown = minf(player.cooldown, tuning["dash_cooldown"])

func start_beat_audio() -> void:
	beat_audio.start_section(rhythm.bpm, rhythm.count_in_beats, RhythmGuide.SECTIONS[rhythm.section]["beats"], rhythm.section)
	beat_audio.stream_paused = mode != "playing"

func sync_rhythm_audio() -> void:
	if beat_audio.playing and not beat_audio.stream_paused:
		rhythm.time = maxf(0.0, beat_audio.clock_time() + beat_audio.sync_offset)

func _unhandled_input(event: InputEvent) -> void:
	if mode == "settings":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER and mode != "playing":
			start_run()
		elif event.keycode == KEY_R:
			start_run()
		elif event.keycode == KEY_ESCAPE and mode in ["playing", "paused"]:
			if mode == "playing":
				mode = "paused"
				beat_audio.stream_paused = true
				confirm_audio.stream_paused = true
				show_overlay("PAUSED", "Press ESC to resume\nPress ENTER to restart")
			else:
				mode = "playing"
				beat_audio.stream_paused = false
				confirm_audio.stream_paused = false
				ui.overlay.hide()
		elif event.keycode == KEY_SHIFT:
			try_dash()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		try_dash()

func _physics_process(delta: float) -> void:
	player.aiming = mode == "playing"
	if mode == "playing":
		tick_game(delta)
	if mode not in ["paused", "settings"]:
		tick_effects(delta)
	player.queue_redraw()
	update_ui()
	queue_redraw()

func tick_game(delta: float) -> void:
	elapsed += delta
	sync_rhythm_audio()
	var previous: Vector2 = player.global_position
	var is_dashing: bool = player.dash_left > 0.0
	player.step(delta, current_room.bounds(), enemies)
	for hazard in get_tree().get_nodes_in_group("room_hazards"):
		if current_room.is_ancestor_of(hazard) and hazard.touches_path(previous, player.global_position, PLAYER_RADIUS):
			hurt_player(hazard.damage, not hazard.dash_can_pass_safely)
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if is_dashing and player.dash_hits.has(enemy):
			burst(enemy.global_position, GOLD)
			enemies.remove_at(index)
			enemy.queue_free()
			continue
		enemy.step(delta, player.global_position, current_room.bounds(), tuning, current_room.difficulty)
		if not is_dashing and enemy.global_position.distance_to(player.global_position) < 30.0:
			hurt_player()
	for index in range(bullets.size() - 1, -1, -1):
		var bullet := bullets[index]
		var bullet_previous: Vector2 = bullet["position"]
		bullet["position"] = bullet_previous + (bullet["velocity"] as Vector2) * delta
		var bullet_position: Vector2 = bullet["position"]
		var wall_hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(bullet_previous, bullet_position, 1))
		if not wall_hit.is_empty():
			bullet_position = wall_hit["position"]
		var hit := segment_distance(player.global_position, bullet_previous, bullet_position) < PLAYER_RADIUS + 6.0
		if hit or not wall_hit.is_empty() or not current_room.bounds().has_point(bullet_position):
			bullets.remove_at(index)
			if hit and not is_dashing:
				hurt_player()
	current_room.get_node("Exit").unlocked = enemies.is_empty()
	if mode == "playing" and enemies.is_empty() and current_room.get_node("Exit").contains(player.global_position):
		if room == room_scenes.size():
			finish_run()
		else:
			room += 1
			spawn_room()


func segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end))

func hurt_player(damage: int = 1, ignore_dash_protection: bool = false) -> void:
	if player.invulnerability > 0.0 or (player.dash_protection_left > 0.0 and not ignore_dash_protection) or mode != "playing":
		return
	health = maxi(0, health - damage)
	player.invulnerability = tuning["hurt_grace"]
	burst(player.global_position, PINK)
	if health <= 0:
		mode = "lost"
		beat_audio.stop()
		confirm_audio.stop()
		show_overlay("RUN ENDED", "Time: %.2f s\nRoom reached: %d / %d\nFollow the breathing ring. Press ENTER to try again." % [elapsed, room, room_scenes.size()])

func finish_run() -> void:
	mode = "won"
	beat_audio.stop()
	confirm_audio.stop()
	show_overlay("ALL ROOMS CLEARED", "Time: %.2f s\n\nPractice mode: no scoring.\nTry adjusting the settings for another run." % elapsed)

func burst(location: Vector2, color: Color) -> void:
	for index in range(12):
		var direction := Vector2.RIGHT.rotated(rng.randf_range(0, TAU))
		sparks.append({"position": location, "velocity": direction * rng.randf_range(60, 240), "life": 0.4, "color": color})

func tick_effects(delta: float) -> void:
	for index in range(sparks.size() - 1, -1, -1):
		var spark := sparks[index]
		spark["life"] = float(spark["life"]) - delta
		spark["position"] = (spark["position"] as Vector2) + (spark["velocity"] as Vector2) * delta
		if float(spark["life"]) <= 0:
			sparks.remove_at(index)

func update_ui() -> void:
	ui.feedback_label.text = "DASH: " + (player.rhythm_feedback if player.rhythm_feedback_left > 0 else "—")
	ui.feedback_label.add_theme_color_override("font_color", Color("9baec5"))
	var count_in := rhythm.countdown()
	ui.rhythm_label.text = "%s  |  %d BPM  |  %s" % [rhythm.section_name(), int(rhythm.bpm), "Count-in: %d" % count_in if count_in > 0 else "Dash when the rings meet. You can skip beats to reposition."]
	ui.title_label.text = "SHIFT DASH   |   ROOM %02d / %02d" % [room, room_scenes.size()]
	ui.stats_label.text = "HP %d / %d     TIME %06.2f s     ENEMIES %02d     PRACTICE" % [health, run_max_health, elapsed, enemies.size()]
	ui.footer_label.text = "%s    Mouse: aim    Shift / RMB: dash    Esc: pause    R: restart    F1: settings\n%s / %s" % ["Movement disabled" if tuning["disable_movement"] else "WASD / Arrows: move", ["Free dash (archive)", "Rhythm gated (archive)", "Rhythm gated + impact slowdown"][int(tuning.get("dash_mode", 2))], "DASH READY" if player.cooldown <= 0.0 else "DASH RECHARGING"]

func _draw() -> void:
	for bullet in bullets:
		draw_circle(bullet["position"], 6.0, GOLD)
	for spark in sparks:
		draw_circle(spark["position"], 3.0, Color(spark["color"], float(spark["life"]) / 0.4))
