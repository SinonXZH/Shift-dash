class_name SettingsPanel
extends Control

signal closed

@export var volume_slider: HSlider
@export var volume_value: Label
@export var fullscreen_button: CheckButton
@export var status: Label

@export var apply_button: Button
@export var back_button: Button


func _ready() -> void:
	volume_slider.value_changed.connect(_show_volume)
	apply_button.pressed.connect(_apply)
	back_button.pressed.connect(_close)


func open() -> void:
	volume_slider.set_value_no_signal(AppData.volume * 100.0)
	_show_volume(volume_slider.value)
	fullscreen_button.set_pressed_no_signal(AppData.fullscreen)
	status.text = ""
	show()
	volume_slider.grab_focus()


func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _show_volume(value: float) -> void:
	volume_value.text = "%d%%" % int(value)


func _apply() -> void:
	if AppData.save_settings(volume_slider.value / 100.0, fullscreen_button.button_pressed) != OK:
		status.text = "无法保存设置，请重试。"
		return
	_close()


func _close() -> void:
	hide()
	closed.emit()
