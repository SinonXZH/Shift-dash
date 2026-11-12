class_name GameRoom
extends Node2D

enum CameraMode {
	FIXED,
	FOLLOW,
}

signal camera_change_requested(mode: CameraMode)

@onready var player_spawn: Marker2D = get_node("PlayerSpawn")
@onready var exit_area: Area2D = get_node("Exit")
@onready var camera_anchor: Marker2D = get_node("CameraAnchor")

var objective_done := false


# 由清怪、机关等具体玩法逻辑调用。
func complete_objective() -> void:
	if objective_done:
		return

	objective_done = true
	camera_change_requested.emit(CameraMode.FOLLOW)


func request_fixed_camera() -> void:
	camera_change_requested.emit(CameraMode.FIXED)
