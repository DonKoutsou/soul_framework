@tool
extends BaseFloorLayer

class_name LockLayer

func HandleCell(_cellDat : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.LockCatalogue.size() > index):
		var LData = LockData.new()
		LData.RequiredItem = map.LockCatalogue[index]
		tempData.Locks[Pos] = LData

func GetDebugData(map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for LockPosition in get_used_cells():
		var Index = get_cell_atlas_coords(LockPosition).x
		if (map.LockCatalogue.size() - 1 < Index):
			printerr("Lock of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			continue
		var Dat = map.LockCatalogue[Index]
		
		var TextDrawPos = map_to_local(LockPosition)
		
		var text = "{0}\n{1}".format([Index, Dat.ItemName])
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : DebugStringColor
		}
				
		DebugData["Texts"][TextDrawPos] = textData
	
	return DebugData
