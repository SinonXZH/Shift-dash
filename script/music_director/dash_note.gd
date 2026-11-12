class_name DashNote
extends RefCounted

## Set by the caller only after a dash actually starts.
var triggered := false
## Refreshed by MusicDirector: positive before the note, negative after it.
var seconds_until := 0.0
## Internal local-time anchor, rebased when playback crosses a boundary.
var section_seconds := 0.0
