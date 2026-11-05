extends CanvasLayer

signal applied(values: Dictionary)
signal closed

const SAVE_PATH := "user://debug_settings.cfg"
# key, Chinese label, default, minimum, maximum, step
const FIELDS := [
	["move_speed", "移动速度（像素/秒）", 260.0, 50, 1000, 10],
	["dash_speed", "冲刺速度（像素/秒）", 1500.0, 100, 4000, 50],
	["dash_duration", "冲刺持续时间（秒）", 0.16, 0.04, 1, 0.01],
	["dash_cooldown", "冲刺冷却（秒）", 0.35, 0.04, 3, 0.01],
	["onbeat_cooldown", "爆发冲刺冷却（秒）", 0.20, 0.04, 3, 0.01],
	["onbeat_speed", "爆发速度倍率（距离不变）", 1.8, 1, 3, 0.1],
	["enemy_hit_speed_factor", "普通冲刺每次碰敌保留速度倍率", 0.45, 0.1, 1, 0.05],
	["max_health", "初始生命＊", 3.0, 1, 99, 1],
	["hurt_grace", "受伤无敌时间（秒）", 1.2, 0.1, 5, 0.1],
	["hit_radius", "冲刺击杀判定半径（像素）", 32.0, 10, 100, 1],
	["enemy_speed", "敌人基础移动速度", 70.0, 0, 400, 5],
	["enemy_speed_growth", "每房间增加敌人速度", 13.0, 0, 100, 1],
	["bullet_speed", "敌弹基础速度", 210.0, 10, 1000, 10],
	["bullet_growth", "每房间增加敌弹速度", 25.0, 0, 200, 5],
	["fire_interval", "射击基础间隔（秒）", 2.2, 0.2, 10, 0.1],
	["fire_reduction", "每房间缩短射击间隔（秒）", 0.2, 0, 1, 0.05],
	["bpm", "节拍速度（BPM）†", 120.0, 40, 240, 1],
	["audio_volume", "循环鼓点音量（%）", 65.0, 0, 100, 5],
	["confirm_volume", "合拍确认音量（%）", 70.0, 0, 100, 5],
	["audio_offset", "节奏校准（毫秒，正值使提示提前）", 0.0, -200, 200, 5],
	["count_in", "准备拍数†", 4.0, 1, 8, 1],
	["preview", "呼吸环提前提示（秒）†", 1.0, 0.2, 2, 0.05],
	["perfect", "完美判定窗口（±秒）", 0.10, 0.01, 0.3, 0.01],
	["good", "合拍判定窗口（±秒）", 0.20, 0.02, 0.4, 0.01],
	["ring_radius", "呼吸环起始半径（像素）", 82.0, 32, 160, 2],
	["feedback_duration", "底部判定显示时间（秒）", 0.4, 0.1, 2, 0.1],
]

var values: Dictionary = {}
var inputs: Dictionary = {}
var screen: Control
var status: Label
var disable_movement: CheckBox
var dash_mode: OptionButton


func initialize(font: Font) -> void:
	layer = 20
	var saved := ConfigFile.new()
	var loaded := saved.load(SAVE_PATH) == OK
	for field in FIELDS:
		var value: Variant = saved.get_value("tuning", field[0], field[2]) if loaded else field[2]
		values[field[0]] = clampf(float(value), field[3], field[4]) if value is float or value is int else field[2]
	# Upgrade only the previous stock windows; preserve custom tuning.
	if loaded and int(saved.get_value("meta", "version", 1)) < 3:
		if is_equal_approx(values["perfect"], 0.06):
			values["perfect"] = 0.10
		if is_equal_approx(values["good"], 0.12):
			values["good"] = 0.20
	values["disable_movement"] = bool(saved.get_value("tuning", "disable_movement", false)) if loaded else false
	values["dash_mode"] = clampi(int(saved.get_value("tuning", "dash_mode", 2)), 0, 2) if loaded else 2
	if loaded and int(saved.get_value("meta", "version", 1)) < 5:
		values["dash_mode"] = 2
	values["good"] = maxf(values["good"], values["perfect"])
	values["dash_cooldown"] = maxf(values["dash_cooldown"], values["dash_duration"])
	values["onbeat_cooldown"] = clampf(values["onbeat_cooldown"], values["dash_duration"], values["dash_cooldown"])
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	screen.theme = theme
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(220, 60)
	panel.size = Vector2(840, 680)
	screen.add_child(panel)
	var title := Label.new()
	title.text = "调试设置    F1 / Esc 关闭"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 25)
	panel.add_child(title)
	var hint := Label.new()
	hint.text = "应用后生效；＊下次生成/重开生效；†重置当前节拍并重新倒数。"
	hint.position = Vector2(24, 57)
	hint.add_theme_font_size_override("font_size", 16)
	panel.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 94)
	scroll.size = Vector2(792, 450)
	panel.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	disable_movement = CheckBox.new()
	disable_movement.text = "禁用普通移动（WASD / 方向键），保留鼠标瞄准与冲刺"
	disable_movement.button_pressed = values["disable_movement"]
	list.add_child(disable_movement)
	var mode_row := HBoxContainer.new()
	list.add_child(mode_row)
	var mode_label := Label.new()
	mode_label.text = "冲刺行为模式"
	mode_label.custom_minimum_size.x = 300
	mode_row.add_child(mode_label)
	dash_mode = OptionButton.new()
	dash_mode.add_item("自由冲刺（旧模式存档）", 0)
	dash_mode.add_item("节奏限定（无减速存档）", 1)
	dash_mode.add_item("节奏限定＋碰敌减速（当前）", 2)
	dash_mode.select(values["dash_mode"])
	mode_row.add_child(dash_mode)
	for field in FIELDS:
		var row := HBoxContainer.new()
		list.add_child(row)
		var label := Label.new()
		label.text = field[1]
		label.custom_minimum_size.x = 510
		row.add_child(label)
		var input := SpinBox.new()
		input.min_value = field[3]
		input.max_value = field[4]
		input.step = field[5]
		input.value = values[field[0]]
		input.custom_minimum_size = Vector2(230, 34)
		row.add_child(input)
		inputs[field[0]] = input
	status = Label.new()
	status.position = Vector2(24, 554)
	status.size = Vector2(792, 44)
	status.add_theme_font_size_override("font_size", 16)
	panel.add_child(status)
	var actions := HBoxContainer.new()
	actions.position = Vector2(24, 612)
	actions.add_theme_constant_override("separation", 16)
	panel.add_child(actions)
	for caption in ["应用并保存", "恢复默认值", "关闭"]:
		var button := Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(245, 44)
		actions.add_child(button)
		match caption:
			"应用并保存": button.pressed.connect(apply_values)
			"恢复默认值": button.pressed.connect(reset_fields)
			"关闭": button.pressed.connect(func(): closed.emit())
	screen.hide()


func open() -> void:
	dash_mode.select(values["dash_mode"])
	disable_movement.button_pressed = values["disable_movement"]
	for key in inputs:
		inputs[key].value = values[key]
		inputs[key].get_line_edit().text = str(values[key])
	status.text = "调整数值后点击“应用并保存”；关闭会放弃未应用的修改。"
	screen.show()


func reset_fields() -> void:
	dash_mode.select(2)
	disable_movement.button_pressed = false
	for field in FIELDS:
		inputs[field[0]].value = field[2]
		inputs[field[0]].get_line_edit().text = str(field[2])
	status.text = "已填入默认值，点击“应用并保存”后生效。"


func apply_values() -> void:
	for key in inputs:
		inputs[key].apply()
	if inputs["perfect"].value > inputs["good"].value:
		status.text = "无法应用：完美窗口不能大于合拍窗口。"
		return
	if inputs["dash_cooldown"].value < inputs["dash_duration"].value:
		status.text = "无法应用：冲刺冷却不能短于持续时间。"
		return
	if inputs["onbeat_cooldown"].value < inputs["dash_duration"].value or inputs["onbeat_cooldown"].value > inputs["dash_cooldown"].value:
		status.text = "无法应用：合拍冷却需介于冲刺持续时间与普通冷却之间。"
		return
	for key in inputs:
		values[key] = inputs[key].value
	values["disable_movement"] = disable_movement.button_pressed
	values["dash_mode"] = dash_mode.get_selected_id()
	applied.emit(values.duplicate())
	var saved := ConfigFile.new()
	saved.set_value("meta", "version", 5)
	for key in values:
		saved.set_value("tuning", key, values[key])
	var error := saved.save(SAVE_PATH)
	status.text = "已应用并保存。" if error == OK else "已应用，本次保存失败：%s" % error_string(error)
