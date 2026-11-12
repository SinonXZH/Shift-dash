class_name DashController
extends Node

signal dash_started(timing_offset: float)
signal dash_rejected
signal dash_ended

@export_range(0.0, 0.5, 0.001, "or_greater", "suffix:s")
var hit_window_seconds := 0.15
@export_range(1.0, 2000.0, 1.0, "or_greater") var dash_speed := 900.0
@export_range(1.0, 1000.0, 1.0, "or_greater") var dash_distance := 180.0

var music_director: MusicDirector
var is_dashing: bool:
	get:
		return _remaining_seconds > 0.0

var _remaining_seconds := 0.0
var _direction := Vector2.ZERO


func try_dash(direction: Vector2) -> bool:
	if is_dashing or direction.is_zero_approx() or music_director == null:
		dash_rejected.emit()
		return false
	if get_tree().paused or music_director.is_paused():
		dash_rejected.emit()
		return false

	var neighbors := music_director.get_neighbor_dash_notes()
	var selected: DashNote = null
	# Previous comes first, so equally close notes prefer the past occurrence.
	for note: DashNote in [neighbors.previous, neighbors.next]:
		if note == null or note.triggered or absf(note.seconds_until) > hit_window_seconds:
			continue
		if selected == null or absf(note.seconds_until) < absf(selected.seconds_until):
			selected = note
	if selected == null:
		dash_rejected.emit()
		return false

	_direction = direction.normalized()
	_remaining_seconds = dash_distance / dash_speed
	selected.triggered = true
	dash_started.emit(-selected.seconds_until)
	return true


func get_dash_velocity(delta: float) -> Vector2:
	# Fold a partial final step into the velocity used for this physics frame.
	var step_seconds := minf(delta, _remaining_seconds)
	return _direction * dash_speed * (step_seconds / delta)


func advance(delta: float) -> void:
	if not is_dashing:
		return
	if delta >= _remaining_seconds:
		end_dash()
	else:
		_remaining_seconds -= delta


func end_dash() -> void:
	if not is_dashing:
		return
	reset()
	dash_ended.emit()


func reset() -> void:
	_remaining_seconds = 0.0
	_direction = Vector2.ZERO
