class_name GameHUD
extends CanvasLayer

signal pause_requested(paused: bool)

var world: GameWorld

@onready var level_complete: Control = get_node("LevelComplete")
@onready var result_title: Label = get_node("LevelComplete/Content/Title")
@onready var next_button: Button = get_node("LevelComplete/Content/NextLevel")
@onready var ending_timer: Timer = get_node("LevelComplete/EndingTimer")
@onready var return_button: Button = get_node("LevelComplete/Content/ReturnToLevels")
@onready var result_status: Label = get_node("LevelComplete/Content/Status")
@onready var pause_menu: Control = get_node("PauseMenu")
@onready var resume_button: Button = get_node("PauseMenu/Center/Panel/Content/Resume")
@onready var settings_button: Button = get_node("PauseMenu/Center/Panel/Content/Settings")
@onready var pause_status: Label = get_node("PauseMenu/Center/Panel/Content/Status")
@onready var settings_panel: SettingsPanel = get_node("SettingsPanel")

@onready var save_return_button: Button = get_node("PauseMenu/Center/Panel/Content/SaveAndReturn")
@onready var save_quit_button: Button = get_node("PauseMenu/Center/Panel/Content/SaveAndQuit")

var _progress_saved := false
var _next_level_id := ""


func _ready() -> void:
	next_button.pressed.connect(_go_to_next_level)
	return_button.pressed.connect(_return_from_results)
	ending_timer.timeout.connect(_return_from_results)
	resume_button.pressed.connect(_close_pause_menu)
	settings_button.pressed.connect(_open_settings)
	save_return_button.pressed.connect(save_and_leave.bind(false))
	save_quit_button.pressed.connect(save_and_leave.bind(true))
	settings_panel.closed.connect(_on_settings_closed)


func _input(event: InputEvent) -> void:
	if world == null or world.completed or settings_panel.visible:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if pause_menu.visible:
		_close_pause_menu()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	pause_requested.emit(true)
	pause_status.text = ""
	pause_menu.show()
	resume_button.grab_focus()


func _close_pause_menu() -> void:
	pause_menu.hide()
	pause_requested.emit(false)


func _open_settings() -> void:
	pause_menu.hide()
	settings_panel.open()


func _on_settings_closed() -> void:
	pause_menu.show()
	settings_button.grab_focus()


func save_and_leave(quit_game: bool) -> void:
	if AppData.save_progress(world.level_id if world.completed else "") != OK:
		if world.completed:
			result_status.text = "无法写入存档，请重试。"
		else:
			settings_panel.hide()
			_open_pause_menu()
			pause_status.text = "无法写入存档，请重试。"
		return

	var tree := get_tree()
	if quit_game:
		tree.quit()
	elif tree.change_scene_to_file(AppData.main_menu) == OK:
		tree.paused = false
	else:
		pause_status.text = "已存档，但无法加载主菜单。"


func show_completion() -> void:
	pause_requested.emit(true)
	_next_level_id = AppData.level_catalog.next_level_id(world.level_id)
	var has_next_level := not _next_level_id.is_empty()
	result_title.text = "关卡完成" if has_next_level else "Thank you"
	next_button.visible = has_next_level
	return_button.visible = has_next_level
	return_button.text = "返回关卡选择" if has_next_level else "重试"
	_save_completion()
	level_complete.show()
	if has_next_level:
		next_button.grab_focus()
	else:
		ending_timer.start()


func _save_completion() -> bool:
	_progress_saved = AppData.save_progress(world.level_id) == OK
	result_status.text = "" if _progress_saved else "无法保存关卡进度，继续时将重试。"
	return _progress_saved


func _go_to_next_level() -> void:
	if not _progress_saved and not _save_completion():
		return
	var tree := get_tree()
	AppData.selected_level_id = _next_level_id
	if tree.change_scene_to_file(AppData.game_scene) == OK:
		tree.paused = false
	else:
		AppData.selected_level_id = ""
		result_status.text = "无法载入下一关。"


func _return_from_results() -> void:
	if _progress_saved or _save_completion():
		var target_scene: String = AppData.main_menu if _next_level_id.is_empty() else AppData.level_select
		var tree := get_tree()
		if tree.change_scene_to_file(target_scene) == OK:
			tree.paused = false
			return
		result_status.text = "无法加载菜单。"
	return_button.show()
	return_button.grab_focus()


func reset_result() -> void:
	ending_timer.stop()
	_next_level_id = ""
	_progress_saved = false
	level_complete.hide()
	pause_menu.hide()
	settings_panel.hide()
