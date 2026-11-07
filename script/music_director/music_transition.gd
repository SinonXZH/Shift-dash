class_name MusicTransition
extends Resource

@export var source: MusicSection
@export var target: MusicSection
## Seconds on the source audio. -1 uses the loop boundary or the end of the audio.
@export_range(-1.0, 60.0, 0.001, "or_greater", "suffix:s")
var source_exit_seconds := -1.0
## Seconds on the target audio. Zero starts from the beginning.
@export_range(0.0, 60.0, 0.001, "or_greater", "suffix:s")
var target_start_seconds := 0.0
