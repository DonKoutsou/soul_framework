@tool
extends BaseFloorLayer

class_name ProjectileSwitchLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x
	
	if (index != -1 and map.ProjectileSwitchCatalogue.size() > index):
		var SwitchData = ProjectileSwitchData.new()
		SwitchData.Info = map.ProjectileSwitchCatalogue[index].duplicate()
		SwitchData.Pos = Pos
		cellDat.Custom_Data["ProjectileSwitch"] = SwitchData

func GetDebugData(map : Map, floor : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for ProjectileSwitchPosition in get_used_cells():

		var Index = get_cell_atlas_coords(ProjectileSwitchPosition).x
		
		if (map.ProjectileSwitchCatalogue.size() - 1 < Index):
			printerr("Projectile switch of Index {0} hasn't been configured in {1}".format([Index, map.LocationName.keys()[map.LevelName]]))
			continue
			
		var Dat = map.ProjectileSwitchCatalogue[Index]
		
		var TextDrawPos = map_to_local(ProjectileSwitchPosition)
		var text = "{0}\n{1}".format([Index, ProjectileSwitchData.SwitchElement.keys()[Dat.Element]])
		
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		TextDrawPos.x -= textSize.x / 2.0
		
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : DebugStringColor
		}
		
		DebugData["Texts"][TextDrawPos] = textData
		
		if (Dat is DoorProjectileSwitchCallInfo):
			var UnlockPosition = Dat.DoorLoc
			if (UnlockPosition == Vector3i.ZERO):
				DebugData["Lines"].append(map_to_local(ProjectileSwitchPosition))
				DebugData["Lines"].append(map_to_local(ProjectileSwitchPosition))
				
				var lineText = var_to_str(Vector3i(ProjectileSwitchPosition.x, floor, ProjectileSwitchPosition.y)).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(ProjectileSwitchPosition)
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(lineText, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : lineText,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData
			else:
				DebugData["Lines"].append(map_to_local(ProjectileSwitchPosition))
				DebugData["Lines"].append(map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)))
				
				var lineText = var_to_str(UnlockPosition).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z))
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(lineText, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : lineText,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData

		if (Dat is BridgeProjectileSwitchCallInfo):
			var UnlockPositions = Dat.FloorPos
			for Pos in UnlockPositions:
				DebugData["Lines"].append(map_to_local(Vector2(Pos.x, Pos.z)))
				DebugData["Lines"].append(map_to_local(ProjectileSwitchPosition))
				
				var lineText = var_to_str(Vector3i(ProjectileSwitchPosition.x, floor, ProjectileSwitchPosition.y)).erase(0, 8)
				
				var LineTextDrawPos = map_to_local(ProjectileSwitchPosition)
				var LinetextSize = ThemeDB.fallback_font.get_multiline_string_size(lineText, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
				LineTextDrawPos.x -= LinetextSize.x / 2.0
				
				var linetextData : Dictionary[String, Variant] = {
					"text" : lineText,
					"color" : DebugStringColor
				}
				
				DebugData["Texts"][LineTextDrawPos] = linetextData

	return DebugData
