class_name LevelCatalog
extends Resource

## Array order determines the level sequence.
@export var levels: Array[LevelEntry] = []


func index_of(level_id: String) -> int:
	for index in levels.size():
		if levels[index].id == level_id:
			return index
	return -1


func first_level_id() -> String:
	return levels[0].id


func next_level_id(level_id: String) -> String:
	var index := index_of(level_id)
	if index < 0 or index + 1 >= levels.size():
		return ""
	return levels[index + 1].id
