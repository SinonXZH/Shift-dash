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


func configure_music(player: Player, director: MusicDirector) -> void:
	for zone in _get_music_zones():
		zone.player = player
		var handler := _on_music_requested.bind(zone, director)
		if not zone.section_requested.is_connected(handler):
			zone.section_requested.connect(handler)


func _on_music_requested(section: MusicSection, zone: MusicZone, director: MusicDirector) -> void:
	if director.request_section(section):
		zone.accept_request()


func reset_music_zones() -> void:
	for zone in _get_music_zones():
		zone.reset_trigger()


func _get_music_zones() -> Array[MusicZone]:
	var result: Array[MusicZone] = []
	var zones := get_node_or_null("MusicZones")
	if zones == null:
		return result
	for node in zones.find_children("*", "Area2D", true, false):
		if node is MusicZone:
			result.append(node as MusicZone)
	return result


# 由清怪、机关等具体玩法逻辑调用。
func complete_objective() -> void:
	if objective_done:
		return

	objective_done = true
	camera_change_requested.emit(CameraMode.FOLLOW)


func request_fixed_camera() -> void:
	camera_change_requested.emit(CameraMode.FIXED)
