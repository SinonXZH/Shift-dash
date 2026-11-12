extends Node

@onready var music_director: MusicDirector = get_node("MusicDirector")
@onready var world: GameWorld = get_node("World")
@onready var player: Player = world.player
@onready var hud: GameHUD = get_node("HUD")


func _ready() -> void:
	player.dash_controller.music_director = music_director
	world.dash_ring.music_director = music_director
	if not world.load_selected_level():
		get_tree().change_scene_to_file.call_deferred(AppData.level_select)
		return

	hud.world = world
	hud.pause_requested.connect(set_paused)
	world.level_completed.connect(hud.show_completion)
	get_tree().set_auto_accept_quit(false)


func _exit_tree() -> void:
	get_tree().set_auto_accept_quit(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready() and hud.world != null:
		hud.save_and_leave(true)


func set_paused(paused: bool) -> void:
	music_director.set_paused(paused)
	get_tree().paused = paused


func restart() -> void:
	world.reset_player()
	hud.reset_result()
	music_director.start(music_director.initial_section)
	set_paused(false)
