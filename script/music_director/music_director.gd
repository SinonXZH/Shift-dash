class_name MusicDirector
extends Node

signal section_changed(section: MusicSection)
signal section_looped

@export var initial_section: MusicSection
## Load MusicTransition resources directly inside this folder at startup.
@export_dir var transitions_directory := ""

@onready var _audio_player: AudioStreamPlayer = $PrimaryMusic

var _current_section: MusicSection
var _current_dash_points := PackedFloat64Array()
var _position_seconds := 0.0
var _playback_start_seconds := 0.0
var _transitions: Array[MusicTransition] = []

var _target_section: MusicSection
var _target_stream: AudioStream
var _target_start_seconds := 0.0
var _source_exit_seconds := 0.0
var _wait_for_loop := false


func _ready() -> void:
	_audio_player.finished.connect(_on_audio_finished)
	_load_transitions()
	if initial_section != null:
		start(initial_section)


func _process(_delta: float) -> void:
	if _current_section == null or _audio_player.stream_paused or not _audio_player.playing:
		return
	_update_position()
	if _target_section != null and not _wait_for_loop and _position_seconds >= _source_exit_seconds:
		_switch_section()
	elif _position_seconds >= _current_section.playback_end_seconds():
		_finish_section()


func start(section: MusicSection) -> bool:
	var stream := section.playback_stream()
	if stream == null:
		return false
	stop()
	_begin_section(section, stream, 0.0)
	return true


func stop() -> void:
	_audio_player.stop()
	_audio_player.stream_paused = false
	_audio_player.stream = null
	_current_section = null
	_current_dash_points = PackedFloat64Array()
	_position_seconds = 0.0
	cancel_transition()


func set_paused(paused: bool) -> void:
	if _audio_player.playing and not _audio_player.stream_paused:
		_update_position()
	_audio_player.stream_paused = paused


## Schedule the target at the next occurrence of the source exit.
func request_section(target: MusicSection) -> bool:
	cancel_transition()
	if _current_section == null or target == _current_section:
		return false

	var rule := _find_transition(target)
	var exit_seconds := _current_section.playback_end_seconds()
	var entry_seconds := 0.0
	if rule != null:
		if rule.source_exit_seconds != -1.0:
			exit_seconds = rule.source_exit_seconds
		entry_seconds = rule.target_start_seconds
	if exit_seconds < 0.0 or exit_seconds > _current_section.playback_end_seconds():
		push_error("MusicTransition.source_exit_seconds is outside the source audio.")
		return false
	if entry_seconds < 0.0 or entry_seconds >= target.playback_end_seconds():
		push_error("MusicTransition.target_start_seconds is outside the target audio.")
		return false

	if _audio_player.playing and not _audio_player.stream_paused:
		_update_position()
	var exit_was_passed := exit_seconds < _position_seconds
	if exit_was_passed and (
		not _current_section.is_looping() or exit_seconds < _current_section.loop_start_seconds
	):
		push_error("MusicTransition: the source exit has already passed and will not repeat.")
		return false
	var stream := target.playback_stream()
	if stream == null:
		return false

	_target_section = target
	_target_stream = stream
	_target_start_seconds = entry_seconds
	_source_exit_seconds = exit_seconds
	_wait_for_loop = exit_was_passed
	# A finished linear track has no further process updates to execute this request.
	if not _audio_player.playing and not _audio_player.stream_paused:
		_switch_section()
	return true


func cancel_transition() -> void:
	_target_section = null
	_target_stream = null
	_wait_for_loop = false


## Null when stopped. Position is measured from the start of the current audio.
func get_position() -> Variant:
	if _current_section == null:
		return null
	return {"section": _current_section, "section_seconds": _position_seconds}


## Seconds until each upcoming dash point, including a scheduled target's points.
## Hit windows, grades and rewards belong to the caller.
func get_upcoming_dash_notes(lookahead_seconds: float) -> PackedFloat64Array:
	var notes := PackedFloat64Array()
	if _current_section == null:
		return notes

	var section := _current_section
	var points := _current_dash_points
	var audio_start := _position_seconds
	var seconds_until_segment := 0.0
	var target := _target_section
	var wait_for_loop := _wait_for_loop
	while seconds_until_segment <= lookahead_seconds:
		var audio_end := section.playback_end_seconds()
		if target != null and not wait_for_loop:
			audio_end = _source_exit_seconds
		for point in points:
			var seconds_until_note := seconds_until_segment + point - audio_start
			if point >= audio_start and point < audio_end and seconds_until_note <= lookahead_seconds:
				notes.append(seconds_until_note)

		seconds_until_segment += audio_end - audio_start
		if target != null and not wait_for_loop:
			section = target
			points = section.sorted_dash_points()
			audio_start = _target_start_seconds
			target = null
		elif section.is_looping():
			audio_start = section.loop_start_seconds
			wait_for_loop = false
		else:
			break
	return notes


func _load_transitions() -> void:
	_transitions.clear()
	if transitions_directory.is_empty():
		return
	if not DirAccess.dir_exists_absolute(transitions_directory):
		push_error("MusicDirector: transition folder does not exist: " + transitions_directory)
		return
	var file_names := ResourceLoader.list_directory(transitions_directory)
	file_names.sort()
	for file_name in file_names:
		if file_name.get_extension() in ["tres", "res"]:
			var resource := ResourceLoader.load(transitions_directory.path_join(file_name))
			if resource is MusicTransition:
				_transitions.append(resource)


func _find_transition(target: MusicSection) -> MusicTransition:
	for rule in _transitions:
		if rule.source == _current_section and rule.target == target:
			return rule
	return null


func _begin_section(section: MusicSection, stream: AudioStream, start_seconds: float) -> void:
	_current_section = section
	_current_dash_points = section.sorted_dash_points()
	# The director restarts each loop explicitly, so it can reset local progress.
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	else:
		stream.loop = false
	_audio_player.stream = stream
	_play_from(start_seconds)
	section_changed.emit(section)


func _play_from(audio_seconds: float) -> void:
	_position_seconds = audio_seconds
	_playback_start_seconds = audio_seconds
	_audio_player.play(audio_seconds)


func _update_position() -> void:
	var audible_seconds := _audio_player.get_playback_position()
	audible_seconds += AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	_position_seconds = clampf(
		maxf(_position_seconds, audible_seconds),
		_playback_start_seconds, _current_section.playback_end_seconds()
	)


func _switch_section() -> void:
	var section := _target_section
	var stream := _target_stream
	var entry_seconds := _target_start_seconds
	cancel_transition()
	_audio_player.stop()
	_begin_section(section, stream, entry_seconds)


func _on_audio_finished() -> void:
	_position_seconds = _current_section.playback_end_seconds()
	_finish_section()


func _finish_section() -> void:
	if _target_section != null and not _wait_for_loop:
		_switch_section()
	elif _current_section.is_looping():
		_wait_for_loop = false
		_play_from(_current_section.loop_start_seconds)
		section_looped.emit()
	else:
		_audio_player.stop()
