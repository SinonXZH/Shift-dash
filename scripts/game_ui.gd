extends CanvasLayer
signal start_requested
signal settings_requested
@onready var title_label: Label = $HUD/Title
@onready var stats_label: Label = $HUD/Stats
@onready var rhythm_label: Label = $HUD/Rhythm
@onready var footer_label: Label = $HUD/Footer
@onready var feedback_label: Label = $HUD/Feedback
@onready var overlay: Panel = $HUD/Overlay
@onready var overlay_text: Label = $HUD/Overlay/Message

func _ready() -> void:
	$HUD/Settings.pressed.connect(func(): settings_requested.emit())
	$HUD/Overlay/Start.pressed.connect(func(): start_requested.emit())
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func show_overlay(heading: String, body: String) -> void:
	overlay_text.text = heading + "\n\n" + body
	overlay.show()
