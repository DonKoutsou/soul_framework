@tool
extends BaseFloorLayer

class_name MovableLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, _tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index != -1 and map.MovableCatalogue.size() > index):
		var MoveData = MovableData.new()
		MoveData.Info = map.MovableCatalogue[index].duplicate()
		cellDat.Custom_Data["Movable"] = MoveData

func GetDebugData(map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for MovablePosition in get_used_cells():
		
		var Index = get_cell_atlas_coords(MovablePosition).x
		var text : String = ""
		var col = DebugStringColor
		
		if (map.MovableCatalogue.size() - 1 < Index):
			printerr("Movable of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			text = "Invalid"
			col = Color(1,0,0)
		else:
			var Dat = map.MovableCatalogue[Index]
			text = "{0}\n{1}".format([Index, PreassuerPlateData.SwitchElement.keys()[Dat.Element]])
			
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		var TextDrawPos = map_to_local(MovablePosition)
		
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : col
		}
		
		DebugData["Texts"][TextDrawPos] = textData
	
	return DebugData
