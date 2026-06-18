@tool
extends BaseFloorLayer

class_name MonsterLayer

func GetMonsterSpawnsOnRoom(room : Array) -> Array[Vector2i]:
	var Spawns : Array[Vector2i]
	for g : Vector2i in get_used_cells():
		var ID = get_cell_atlas_coords(g)
		if (ID.x == -1):
			continue
		if (room.has(g)):
			Spawns.append(Vector2i(g.x, g.y))
	return Spawns

func GetDebugData(map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for monsterPosition in get_used_cells():
		
		var Index = get_cell_atlas_coords(monsterPosition).x
		
		var text : String = ""
		var col = DebugStringColor
		
		if (map.MonsterCatalogue.size() - 1 < Index):
			printerr("Monster of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			text = "Invalid"
			col = Color(1,0,0)
		else:
			var mon : Monster = load(map.MonsterCatalogue[Index])
			text = mon.MonsterName
			
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		var TextDrawPos = map_to_local(monsterPosition)
		
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : DebugStringColor
		}
		
		DebugData["Texts"][TextDrawPos] = textData
			
	
	return DebugData
