extends Control

@export var levels: VBoxContainer
@export var back_button: Button
@export var status: Label


func _ready() -> void:
	back_button.pressed.connect(_back_to_menu)
	back_button.grab_focus()
	var unlocked: PackedStringArray = AppData.get_unlocked_levels()
	var first_available: Button
	for level: LevelEntry in AppData.level_catalog.levels:
		var button := Button.new()
		button.custom_minimum_size.y = 44.0
		button.disabled = not unlocked.has(level.id)
		button.text = level.title + ("（未解锁）" if button.disabled else "")
		levels.add_child(button)
		button.pressed.connect(_enter_level.bind(level.id))
		if not button.disabled and first_available == null:
			first_available = button
	if first_available != null:
		first_available.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back_to_menu()


func _enter_level(level_id: String) -> void:
	AppData.selected_level_id = level_id
	if get_tree().change_scene_to_packed(AppData.game_scene) != OK:
		AppData.selected_level_id = ""
		status.text = "无法加载关卡。"


func _back_to_menu() -> void:
	if get_tree().change_scene_to_packed(AppData.main_menu) != OK:
		status.text = "无法返回主菜单。"
