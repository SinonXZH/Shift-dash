@tool
extends Node2D
@export var arena_size := Vector2(1152, 552):
	set(value):
		arena_size = value
		queue_redraw()
@export_enum("Intro / Half-time", "Drive / Every beat", "Variation / Syncopated") var rhythm_section := 0
@export_range(1, 10, 1) var difficulty := 1

func _ready() -> void:
	if not Engine.is_editor_hint():
		call_deferred("preview_room")

func preview_room() -> void:
	# F6 on an authored room uses the same gameplay controller as F5.
	if not is_inside_tree() or is_queued_for_deletion():
		return
	if get_tree().current_scene != self:
		return
	var game: Node = load("res://scenes/main.tscn").instantiate()
	var preview_scenes: Array[PackedScene] = [load(scene_file_path)]
	game.room_scenes = preview_scenes
	get_tree().root.add_child(game)
	get_tree().current_scene = game
	game.start_run()
	queue_free()

func bounds() -> Rect2:
	return Rect2(global_position, arena_size)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color("0c1729"))
	for x in range(0, int(arena_size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, arena_size.y), Color("122238"))
	for y in range(0, int(arena_size.y), 48):
		draw_line(Vector2(0, y), Vector2(arena_size.x, y), Color("122238"))
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color("29415b"), false, 3)
