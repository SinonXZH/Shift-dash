class_name GameWorld
extends Node2D

signal level_completed

@onready var game_camera: Camera2D = get_node("CameraDirector/Camera2D")
@onready var music_director: MusicDirector = get_node("../MusicDirector")

@onready var player: Player = get_node("Player")
@onready var dash_ring: DashRing = get_node("Player/DashRing")
@onready var rooms: Node2D = get_node("Rooms")

var level_id := ""
var completed := false
var _spawn_position := Vector2.ZERO


func load_selected_level() -> bool:
	if not is_instance_valid(music_director):
		push_error("GameWorld requires a music_director reference in the Inspector.")
		return false
	if not is_instance_valid(game_camera):
		push_error("GameWorld requires a game_camera reference in the Inspector.")
		return false
	level_id = AppData.selected_level_id
	AppData.selected_level_id = ""
	if level_id.is_empty():
		level_id = AppData.level_catalog.first_level_id()
	if not _load_room():
		return false
	reset_player()
	return true


func reset_player() -> void:
	completed = false
	player.reset(_spawn_position)


func _load_room() -> bool:
	var index: int = AppData.level_catalog.index_of(level_id)
	if index < 0:
		return false
	var level: LevelEntry = AppData.level_catalog.levels[index]
	var scene := ResourceLoader.load(level.scene_file, "PackedScene") as PackedScene
	if scene == null:
		return false
	var instance := scene.instantiate()
	var room := instance as GameRoom
	if room == null:
		push_error("Room %s requires a GameRoom script." % level_id)
		instance.free()
		return false
	rooms.add_child(room)
	var spawn := room.player_spawn
	var exit := room.exit_area
	if spawn == null or exit == null:
		push_error("Room %s requires player_spawn and exit_area references." % level_id)
		room.free()
		return false
	_spawn_position = spawn.global_position
	exit.body_entered.connect(_on_exit_body_entered)
	var camera_anchor := room.camera_anchor
	if camera_anchor != null:
		game_camera.global_position = camera_anchor.global_position
	return true


func _on_exit_body_entered(body: Node2D) -> void:
	if body == player and not completed:
		completed = true
		level_completed.emit()
