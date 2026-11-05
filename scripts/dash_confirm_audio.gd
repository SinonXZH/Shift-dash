extends AudioStreamPlayer
## A short pitched chord, separate from the background percussion and clock.
const SAMPLE_RATE := 22050
var sounds: Array[AudioStreamWAV] = []


func _ready() -> void:
	max_polyphony = 3
	for perfect in [false, true]:
		sounds.append(make_chord(perfect))


func confirm(perfect: bool) -> void:
	stream = sounds[1 if perfect else 0]
	play()


func make_chord(perfect: bool) -> AudioStreamWAV:
	var duration := 0.16
	var count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var value := sin(TAU * 523.25 * t) * 0.34 + sin(TAU * 659.25 * t) * 0.23
		if perfect:
			value += sin(TAU * 1046.5 * t) * 0.18
		var envelope := minf(1.0, t * 700.0) * exp(-t * 30.0) * minf(1.0, (duration - t) * 1000)
		pcm.encode_s16(i * 2, int(value * envelope * 32767))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = pcm
	return wav
