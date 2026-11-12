class_name MusicSection
extends Resource

enum PlaybackMode { PLAY_ONCE, LOOP }
enum DashTimingMode { MANUAL, FIXED_INTERVAL }

@export var audio_stream: AudioStream
@export var playback_mode: PlaybackMode = PlaybackMode.PLAY_ONCE

@export_group("Dash Timing")
## Manual uses Dash Points. Fixed Interval generates points from Dash Start Seconds.
@export var dash_timing_mode: DashTimingMode = DashTimingMode.MANUAL
## Seconds from the start of the audio. Points can be entered in any order.
@export var dash_points: PackedFloat64Array
## First dash point, measured from the start of the audio.
@export_range(0.0, 60.0, 0.001, "or_greater", "suffix:s")
var dash_start_seconds := 0.0
## Time between dash points. Used only in Fixed Interval mode.
@export_range(0.001, 60.0, 0.001, "or_greater", "suffix:s")
var dash_interval_seconds := 0.5

@export_group("Loop Range")
@export_range(0.0, 60.0, 0.001, "or_greater", "suffix:s")
var loop_start_seconds := 0.0
## Leave at zero to loop at the end of the audio. Custom end points require WAV.
@export_range(0.0, 60.0, 0.001, "or_greater", "suffix:s")
var loop_end_seconds := 0.0


func is_looping() -> bool:
	return playback_mode == PlaybackMode.LOOP


func playback_end_seconds() -> float:
	if is_looping() and loop_end_seconds != 0.0:
		return loop_end_seconds
	return audio_stream.get_length() if audio_stream != null else 0.0


func loop_duration_seconds() -> float:
	return playback_end_seconds() - loop_start_seconds if is_looping() else 0.0


func sorted_dash_points() -> PackedFloat64Array:
	var points := PackedFloat64Array()
	var end := playback_end_seconds()
	if dash_timing_mode == DashTimingMode.FIXED_INTERVAL:
		if dash_interval_seconds <= 0.0 or dash_start_seconds < 0.0:
			push_error("MusicSection: dash interval must be positive and dash start must be nonnegative.")
			return points
		var point_count := ceili((end - dash_start_seconds) / dash_interval_seconds)
		for index in range(point_count):
			var point := dash_start_seconds + index * dash_interval_seconds
			if point < end:
				points.append(point)
		return points
	for point in dash_points:
		if point >= 0.0 and point < end:
			points.append(point)
	points.sort()
	return points


func playback_stream() -> AudioStream:
	if not (audio_stream is AudioStreamWAV or audio_stream is AudioStreamOggVorbis):
		push_error("MusicSection.audio_stream: assign a WAV or OGG audio stream.")
		return null
	if is_looping():
		var end := playback_end_seconds()
		if loop_start_seconds < 0.0 or end <= loop_start_seconds or end > audio_stream.get_length():
			push_error("MusicSection: loop start must be before loop end, within the audio duration.")
			return null

	# Each section can set its own loop without changing the imported audio.
	if audio_stream is AudioStreamWAV:
		var wav := audio_stream.duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
		if is_looping():
			wav.loop_begin = roundi(loop_start_seconds * wav.mix_rate)
			wav.loop_end = roundi(playback_end_seconds() * wav.mix_rate)
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav
	if is_looping() and playback_end_seconds() != audio_stream.get_length():
		push_error("MusicSection.loop_end_seconds: use 0 for OGG to loop at the audio end.")
		return null
	var ogg := audio_stream.duplicate() as AudioStreamOggVorbis
	ogg.loop = is_looping()
	ogg.loop_offset = loop_start_seconds if is_looping() else 0.0
	return ogg
