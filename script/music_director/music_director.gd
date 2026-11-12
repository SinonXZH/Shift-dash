class_name MusicDirector
extends Node

signal section_changed(section: MusicSection)
signal section_looped
## Emitted when playback reaches a note, even if a dash already used it.
signal dash_note_reached(note: DashNote)

@export var initial_section: MusicSection
## Load MusicTransition resources directly inside this folder at startup.
@export_dir var transitions_directory := ""


class PendingSection:
	extends RefCounted

	var section: MusicSection
	var stream: AudioStream
	var entry_seconds := 0.0
	var source_exit_seconds := 0.0
	var wait_for_loop := false
	var notes: Array[DashNote] = []
	var loop_notes: Array[DashNote] = []


@onready var audio_player: AudioStreamPlayer = get_node("PrimaryMusic")

var _current_section: MusicSection
var _dash_notes: Array[DashNote] = []
# Keep only the next loop's objects, so early triggers survive the boundary.
var _loop_dash_notes: Array[DashNote] = []
var _previous_dash_note: DashNote
var _next_note_index := 0
var _position_seconds := 0.0
var _playback_start_seconds := 0.0
var _transitions: Array[MusicTransition] = []
var _pending: PendingSection


func _ready() -> void:
	audio_player.finished.connect(_on_audio_finished)
	_load_transitions()
	if initial_section != null:
		start(initial_section)


func _process(_delta: float) -> void:
	_refresh_playback_state()


func start(section: MusicSection) -> bool:
	var stream := section.playback_stream()
	if stream == null:
		return false
	stop()
	_dash_notes = _build_dash_notes(section, 0.0)
	_loop_dash_notes = _build_loop_notes(section)
	_begin_section(section, stream, 0.0)
	return true


func stop() -> void:
	audio_player.stop()
	audio_player.stream_paused = false
	audio_player.stream = null
	_current_section = null
	_dash_notes.clear()
	_loop_dash_notes.clear()
	_previous_dash_note = null
	_next_note_index = 0
	_position_seconds = 0.0
	cancel_transition()


func is_paused() -> bool:
	return audio_player.stream_paused


func set_paused(paused: bool) -> void:
	_refresh_playback_state()
	audio_player.stream_paused = paused


## Schedule the target at the next occurrence of the source exit.
func request_section(target: MusicSection) -> bool:
	_refresh_playback_state()
	cancel_transition()
	if _current_section == null or target == _current_section:
		return false

	var exit_seconds := _current_section.playback_end_seconds()
	var entry_seconds := 0.0
	var rule := _find_transition(target)
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

	var exit_was_passed := exit_seconds < _position_seconds
	if exit_was_passed and (
		not _current_section.is_looping() or exit_seconds < _current_section.loop_start_seconds
	):
		push_error("MusicTransition: the source exit has already passed and will not repeat.")
		return false
	var stream := target.playback_stream()
	if stream == null:
		return false

	_pending = PendingSection.new()
	_pending.section = target
	_pending.stream = stream
	_pending.entry_seconds = entry_seconds
	_pending.source_exit_seconds = exit_seconds
	_pending.wait_for_loop = exit_was_passed
	_pending.notes = _build_dash_notes(target, entry_seconds)
	_pending.loop_notes = _build_loop_notes(target)
	# A finished linear track has no further audio progress to reach the exit.
	if not audio_player.playing and not audio_player.stream_paused:
		_switch_section()
	return true


func cancel_transition() -> void:
	_pending = null


## Null when stopped. Position is measured from the start of the current audio.
func get_position() -> Variant:
	_refresh_playback_state()
	if _current_section == null:
		return null
	return {"section": _current_section, "section_seconds": _position_seconds}


## Shared references. The caller decides the hit window and writes triggered.
## Only the returned notes have their seconds_until refreshed by this query.
func get_neighbor_dash_notes() -> Dictionary:
	_refresh_playback_state()
	var next: DashNote = null
	if _current_section != null:
		next = _find_next_dash_note()
	return {"previous": _previous_dash_note, "next": next}


func _find_next_dash_note() -> DashNote:
	var end := _playback_end()
	var next := _find_note(_dash_notes, _position_seconds, end, 0.0)
	if next != null:
		return next

	var offset := end - _position_seconds
	if _pending == null or _pending.wait_for_loop:
		if not _current_section.is_looping():
			return null
		var loop_start := _current_section.loop_start_seconds
		var loop_end := _current_section.playback_end_seconds()
		if _pending != null:
			loop_end = _pending.source_exit_seconds
		next = _find_note(_loop_dash_notes, loop_start, loop_end, offset)
		if next != null or _pending == null:
			return next
		offset += loop_end - loop_start

	next = _find_note(
		_pending.notes, _pending.entry_seconds, _pending.section.playback_end_seconds(), offset
	)
	if next != null or not _pending.section.is_looping():
		return next
	offset += _pending.section.playback_end_seconds() - _pending.entry_seconds
	return _find_note(
		_pending.loop_notes, _pending.section.loop_start_seconds,
		_pending.section.playback_end_seconds(), offset
	)


func _find_note(notes: Array[DashNote], start: float, end: float, offset: float) -> DashNote:
	for note in notes:
		if note.section_seconds >= start and note.section_seconds < end:
			var seconds_until := offset + note.section_seconds - start
			if seconds_until > 0.0:
				note.seconds_until = seconds_until
				return note
	return null


## Numeric preview only: never allocate or replace playable DashNote objects.
func get_upcoming_dash_notes(lookahead_seconds: float) -> PackedFloat64Array:
	_refresh_playback_state()
	var result := PackedFloat64Array()
	if _current_section == null:
		return result
	var section := _current_section
	var position := _position_seconds
	var offset := 0.0
	var pending := _pending
	var wait_for_loop := pending != null and pending.wait_for_loop
	while offset <= lookahead_seconds:
		var end := section.playback_end_seconds()
		if pending != null and not wait_for_loop:
			end = pending.source_exit_seconds
		for point in section.sorted_dash_points():
			var seconds_until := offset + point - position
			if point >= position and point < end and seconds_until <= lookahead_seconds:
				result.append(seconds_until)
		offset += end - position
		if pending != null and not wait_for_loop:
			section = pending.section
			position = pending.entry_seconds
			pending = null
		elif section.is_looping():
			position = section.loop_start_seconds
			wait_for_loop = false
		else:
			break
	return result


func _build_dash_notes(section: MusicSection, entry: float) -> Array[DashNote]:
	var notes: Array[DashNote] = []
	for point in section.sorted_dash_points():
		if point >= entry:
			var note := DashNote.new()
			note.section_seconds = point
			notes.append(note)
	return notes


func _build_loop_notes(section: MusicSection) -> Array[DashNote]:
	var notes: Array[DashNote] = []
	if section.is_looping():
		notes = _build_dash_notes(section, section.loop_start_seconds)
	return notes


func _collect_passed_dash_notes() -> void:
	var end := _playback_end()
	while _next_note_index < _dash_notes.size():
		var note := _dash_notes[_next_note_index]
		if note.section_seconds > _position_seconds or note.section_seconds >= end:
			break
		_previous_dash_note = note
		_next_note_index += 1
		note.seconds_until = note.section_seconds - _position_seconds
		# Let listeners query playback after the current update finishes.
		dash_note_reached.emit.call_deferred(note)
	if _previous_dash_note != null:
		_previous_dash_note.seconds_until = _previous_dash_note.section_seconds - _position_seconds


func _playback_end() -> float:
	if _pending != null and not _pending.wait_for_loop:
		return _pending.source_exit_seconds
	return _current_section.playback_end_seconds()


func _refresh_playback_state() -> void:
	if _current_section == null or audio_player.stream_paused:
		return
	if audio_player.playing:
		_update_position()
		_position_seconds = minf(_position_seconds, _playback_end())
		_collect_passed_dash_notes()
		if _position_seconds >= _playback_end():
			_finish_section()


## Carry the last actual note across the boundary using its local-time anchor.
func _rebase_previous_dash_note(entry: float) -> void:
	if _previous_dash_note != null:
		_previous_dash_note.section_seconds += entry - _position_seconds


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


func _begin_section(section: MusicSection, stream: AudioStream, entry: float) -> void:
	_current_section = section
	# Loops restart explicitly so local playback progress can reset.
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	else:
		stream.loop = false
	audio_player.stream = stream
	_play_from(entry)
	section_changed.emit(section)


func _play_from(audio_seconds: float) -> void:
	_position_seconds = audio_seconds
	_playback_start_seconds = audio_seconds
	_next_note_index = 0
	audio_player.play(audio_seconds)
	_collect_passed_dash_notes()


func _update_position() -> void:
	var audible_seconds := audio_player.get_playback_position()
	audible_seconds += AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	_position_seconds = clampf(
		maxf(_position_seconds, audible_seconds),
		_playback_start_seconds, _current_section.playback_end_seconds()
	)


func _switch_section() -> void:
	var pending := _pending
	_rebase_previous_dash_note(pending.entry_seconds)
	_dash_notes = pending.notes
	_loop_dash_notes = pending.loop_notes
	_pending = null
	audio_player.stop()
	_begin_section(pending.section, pending.stream, pending.entry_seconds)


func _on_audio_finished() -> void:
	_position_seconds = _playback_end()
	_collect_passed_dash_notes()
	_finish_section()


func _finish_section() -> void:
	if _pending != null and not _pending.wait_for_loop:
		_switch_section()
	elif _current_section.is_looping():
		_rebase_previous_dash_note(_current_section.loop_start_seconds)
		_dash_notes = _loop_dash_notes
		_loop_dash_notes = _build_loop_notes(_current_section)
		if _pending != null:
			_pending.wait_for_loop = false
		_play_from(_current_section.loop_start_seconds)
		section_looped.emit()
	else:
		audio_player.stop()
