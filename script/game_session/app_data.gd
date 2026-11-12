extends Node

const level_catalog = preload("res://resource/level_catalog.tres")
const game_scene = "res://scenes/game_session.tscn"
const main_menu = "res://scenes/ui/main_menu.tscn"
const level_select = "res://scenes/ui/level_select.tscn"

const SAVE_PATH := "user://progress.cfg"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 2
const FIRST_TEST_LEVEL_ID := "room_test_01"

var selected_level_id := ""
var volume := 1.0
var fullscreen := false


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		var stored_volume: Variant = config.get_value("audio", "volume", 1.0)
		if (stored_volume is float or stored_volume is int) and is_finite(stored_volume):
			volume = clampf(stored_volume, 0.0, 1.0)
		var stored_fullscreen: Variant = config.get_value("display", "fullscreen", false)
		if stored_fullscreen is bool:
			fullscreen = stored_fullscreen
	_apply_settings()


func read_save() -> PackedStringArray:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return []
	var version: Variant = config.get_value("save", "version", 0)
	if version == 1:
		var position: Variant = config.get_value("save", "player_position", null)
		var completed: Variant = config.get_value("save", "completed", null)
		if not position is Vector2 or not position.is_finite() or not completed is bool:
			return []
		# The old save format only supported the test room.
		var unlocked := _initial_unlocks()
		if completed:
			_unlock_next(unlocked, FIRST_TEST_LEVEL_ID)
		return unlocked
	var stored: Variant = config.get_value("save", "unlocked_levels", null)
	if version != SAVE_VERSION or not stored is PackedStringArray:
		return []

	var unlocked := _initial_unlocks()
	for stored_id in stored:
		var level_id: String = FIRST_TEST_LEVEL_ID if stored_id == "room_template" else stored_id
		if level_catalog.index_of(level_id) != -1 and not unlocked.has(level_id):
			unlocked.append(level_id)
	return unlocked


func get_unlocked_levels() -> PackedStringArray:
	var unlocked := read_save()
	return _initial_unlocks() if unlocked.is_empty() else unlocked


func save_progress(completed_level_id := "") -> Error:
	var unlocked := get_unlocked_levels()
	if not completed_level_id.is_empty():
		_unlock_next(unlocked, completed_level_id)
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "unlocked_levels", unlocked)
	return _write_config(config, SAVE_PATH)


func _initial_unlocks() -> PackedStringArray:
	return PackedStringArray([level_catalog.first_level_id()])


func _unlock_next(unlocked: PackedStringArray, completed_level_id: String) -> void:
	var next_id := level_catalog.next_level_id(completed_level_id)
	if not next_id.is_empty() and not unlocked.has(next_id):
		unlocked.append(next_id)


func save_settings(new_volume: float, new_fullscreen: bool) -> Error:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", new_volume)
	config.set_value("display", "fullscreen", new_fullscreen)
	var error := _write_config(config, SETTINGS_PATH)
	if error == OK:
		volume = new_volume
		fullscreen = new_fullscreen
		_apply_settings()
	return error


func _apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(master, volume == 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


func _write_config(config: ConfigFile, path: String) -> Error:
	var temporary_path := path + ".tmp"
	var error := config.save(temporary_path)
	if error == OK:
		error = DirAccess.rename_absolute(temporary_path, path)
	return error
