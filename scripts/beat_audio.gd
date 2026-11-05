extends AudioStreamPlayer
## Synthesized PCM loop: count-in, then one repeating bar. No external assets.
const SAMPLE_RATE := 22050
var loop_seconds := 2.0
var loop_total := 0.0
var previous_position := 0.0
var timeline := 0.0
var output_latency := 0.0
var sync_offset := 0.0


func start_section(bpm: float, count_in: float, beats: Array, section: int) -> void:
	stop()
	stream_paused = false
	var beat_seconds := 60.0 / bpm
	var intro_seconds := count_in * beat_seconds
	loop_seconds = 4.0 * beat_seconds
	var sample_count := int(round((intro_seconds + loop_seconds) * SAMPLE_RATE))
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var noise := RandomNumberGenerator.new()
	noise.seed = 808
	for beat in range(int(count_in)):
		add_hit(samples, beat * beat_seconds, "click", 0.35, noise)
	# The accent is exactly the same pattern as the breathing rings.
	for beat in beats:
		add_hit(samples, intro_seconds + float(beat) * beat_seconds, "accent", 0.4, noise)
	for beat in range(4):
		var position_seconds := intro_seconds + beat * beat_seconds
		add_hit(samples, position_seconds, "hat", 0.12, noise)
		if beat % 2 == 0:
			add_hit(samples, position_seconds, "kick", 0.48, noise)
		elif section >= 1:
			add_hit(samples, position_seconds, "snare", 0.22, noise)
		if section >= 2:
			add_hit(samples, position_seconds + beat_seconds * 0.5, "hat", 0.09, noise)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for index in range(sample_count):
		pcm.encode_s16(index * 2, int(clampf(samples[index], -0.95, 0.95) * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = pcm
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = int(round(intro_seconds * SAMPLE_RATE))
	wav.loop_end = sample_count
	stream = wav
	loop_total = 0.0
	previous_position = 0.0
	timeline = 0.0
	output_latency = AudioServer.get_output_latency()
	play()


func clock_time() -> float:
	if not playing or stream_paused:
		return timeline
	var position_seconds := get_playback_position()
	if previous_position - position_seconds > loop_seconds * 0.5:
		loop_total += loop_seconds
	previous_position = position_seconds
	var audible := position_seconds + loop_total + AudioServer.get_time_since_last_mix() - output_latency
	# Prevent tiny mixer-clock regressions; count-in and loops share this clock.
	timeline = maxf(timeline, maxf(0.0, audible))
	return timeline


func add_hit(samples: PackedFloat32Array, at: float, kind: String, gain: float, noise: RandomNumberGenerator) -> void:
	var duration := 0.16 if kind == "kick" else 0.08
	if kind == "hat":
		duration = 0.035
	var start := int(round(at * SAMPLE_RATE))
	var length := int(duration * SAMPLE_RATE)
	for index in range(length):
		if start + index >= samples.size():
			break
		var t := float(index) / SAMPLE_RATE
		var sound := 0.0
		match kind:
			"kick": sound = sin(TAU * (48.0 * t + 7.0 * (1.0 - exp(-t * 22.0)))) * exp(-t * 28.0)
			"snare": sound = (noise.randf_range(-1, 1) * 0.8 + sin(TAU * 180.0 * t) * 0.2) * exp(-t * 55.0)
			"hat": sound = noise.randf_range(-1, 1) * exp(-t * 130.0)
			"accent": sound = (sin(TAU * 880.0 * t) + sin(TAU * 1320.0 * t) * 0.3) * exp(-t * 75.0)
			"click": sound = sin(TAU * 660.0 * t) * exp(-t * 90.0)
		var fade := minf(1.0, t * 1500.0) * minf(1.0, (duration - t) * 1000.0)
		samples[start + index] += sound * gain * fade
