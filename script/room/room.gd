class_name GameRoom
extends Node2D

enum CameraMode {
	FIXED,
	FOLLOW,
}

signal camera_change_requested(mode: CameraMode)

@export var player_spawn: Marker2D
@export var exit_area: Area2D
@export var camera_anchor: Marker2D

var objective_done := false


# 由清怪、机关等具体玩法逻辑调用。
func complete_objective() -> void:
	if objective_done:
		return

	objective_done = true
	camera_change_requested.emit(CameraMode.FOLLOW)


func request_fixed_camera() -> void:
	camera_change_requested.emit(CameraMode.FIXED)
