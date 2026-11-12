class_name DashRing
extends Node2D

@export_range(0.05, 5.0, 0.05, "suffix:s") var approach_seconds := 1.0

var music_director: MusicDirector
var _approach := 0.0
var _has_next_note := false


func _process(_delta: float) -> void:
	var note: DashNote = null
	if music_director != null:
		note = music_director.get_neighbor_dash_notes().next
	_has_next_note = note != null
	if _has_next_note:
		_approach = 1.0 - clampf(note.seconds_until / approach_seconds, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not _has_next_note:
		return
	var radius := lerpf(46.0, 18.0, _approach)
	var color := Color(0.43, 0.91, 0.96, lerpf(0.16, 0.95, _approach))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, 2.0, true)
