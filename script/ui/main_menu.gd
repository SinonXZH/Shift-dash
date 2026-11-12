extends Control

@onready var menu: Control = get_node("Center/Menu")
@onready var continue_button: Button = get_node("Center/Menu/Continue")
@onready var new_game_button: Button = get_node("Center/Menu/NewGame")
@onready var status: Label = get_node("Center/Menu/Status")

@onready var settings_button: Button = get_node("Center/Menu/SettingsButton")
@onready var quit_button: Button = get_node("Center/Menu/Quit")
@onready var settings_panel: SettingsPanel = get_node("SettingsPanel")


func _ready() -> void:
	continue_button.disabled = AppData.read_save().is_empty()
	continue_button.pressed.connect(_open_level_select)
	new_game_button.pressed.connect(_open_level_select)
	settings_button.pressed.connect(_open_settings)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	_focus_start()


func _open_level_select() -> void:
	if get_tree().change_scene_to_file(AppData.level_select) != OK:
		status.text = "无法打开关卡选择。"


func _open_settings() -> void:
	menu.hide()
	settings_panel.open()


func _on_settings_closed() -> void:
	menu.show()
	settings_button.grab_focus()


func _focus_start() -> void:
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()
