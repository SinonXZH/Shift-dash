extends RefCounted
## Shared timeline for the breathing rings and dash timing feedback.
## Beat positions are relative to a repeating four-beat bar, after a count-in.
const BAR_BEATS := 4.0
var bpm := 120.0
var count_in_beats := 4.0
var preview_seconds := 1.0
var perfect_window := 0.10
var good_window := 0.20

const SECTIONS := [
	{"name": "Intro / Half-time", "beats": [0.0, 2.0]},
	{"name": "Drive / Every beat", "beats": [0.0, 1.0, 2.0, 3.0]},
	{"name": "Variation / Syncopated", "beats": [0.0, 1.0, 2.5, 3.5]},
]

var time := 0.0
var section := 0


func reset(section_index: int) -> void:
	section = clampi(section_index, 0, SECTIONS.size() - 1)
	time = 0.0


func advance(delta: float) -> void:
	time += delta


func section_name() -> String:
	return SECTIONS[section]["name"]


func upcoming_offsets() -> Array[float]:
	var offsets: Array[float] = []
	var beat_seconds := 60.0 / bpm
	var count_in := count_in_beats * beat_seconds
	var bar_seconds := BAR_BEATS * beat_seconds
	var current_bar := int(floor((time - count_in) / bar_seconds))
	for bar in range(maxi(0, current_bar - 1), maxi(0, current_bar) + int(ceil(preview_seconds / bar_seconds)) + 2):
		for beat in SECTIONS[section]["beats"]:
			var offset: float = count_in + bar * bar_seconds + float(beat) * beat_seconds - time
			if offset >= -good_window and offset <= maxf(preview_seconds, good_window):
				offsets.append(offset)
	offsets.sort()
	return offsets


func timing_error() -> float:
	var error := INF
	for offset in upcoming_offsets():
		error = minf(error, absf(offset))
	return error


func nearest_dash_beat() -> float:
	# Stable event identity prevents two rewards on opposite sides of one beat.
	var beat_seconds := 60.0 / bpm
	var intro := count_in_beats * beat_seconds
	var bar_seconds := BAR_BEATS * beat_seconds
	var current_bar := int(floor((time - intro) / bar_seconds))
	var nearest := INF
	for bar in range(maxi(0, current_bar - 1), maxi(0, current_bar) + 2):
		for beat in SECTIONS[section]["beats"]:
			var event_time: float = intro + bar * bar_seconds + float(beat) * beat_seconds
			if absf(event_time - time) < absf(nearest - time):
				nearest = event_time
	return nearest


func countdown() -> int:
	var beat_seconds := 60.0 / bpm
	var count_in := count_in_beats * beat_seconds
	return maxi(0, int(ceil((count_in - time) / beat_seconds)))
