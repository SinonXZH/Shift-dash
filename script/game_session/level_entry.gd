class_name LevelEntry
extends Resource

@export var title := ""
@export var _describe := ""
@export_file("*.tscn") var scene_file := ""

var id: String:
	get:
		var path := scene_file
		if path.begins_with("uid://"):
			path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
		return path.get_file().get_basename()
