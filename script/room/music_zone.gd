class_name MusicZone
extends Area2D

signal section_requested(section: MusicSection)

@export var target_section: MusicSection
## Consume only after the director accepts the request. Reset on room retry.
@export var one_shot := false

var player: Player
var _consumed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body != player or not is_instance_valid(player):
		return
	if target_section != null and not (one_shot and _consumed):
		section_requested.emit(target_section)


func accept_request() -> void:
	if one_shot:
		_consumed = true


func reset_trigger() -> void:
	_consumed = false
