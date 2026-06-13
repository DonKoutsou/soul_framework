@tool
extends BaseFloorLayer

class_name ItemLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, _tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	if (index > -1 ):
		if (map.ItemCaralogue.size() <= index):
			printerr("Wrondly configured item catalogue, missing index {0}".format([index]))
			return
		var it = map.ItemCaralogue[index]
		
		var Lock_Index = tempLayerData.Floor.GetLayer(FloorLayer.LayerType.LOCKS).get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x
		
		if (Lock_Index != -1 and map.LockCatalogue.size() > Lock_Index):
			var ChestDat = ChestData.new()
			var LockDat = LockData.new()
			LockDat.RequiredItem = map.LockCatalogue[Lock_Index]
			ChestDat.LockDat = LockDat
			ChestDat.ChestMapPosition = Pos
			ChestDat.ContainedItem = it
			
			var rot = map.GetFloor(Pos.y).GetLayer(FloorLayer.LayerType.LOCKS).GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
			var Trans = Transform3D(Basis().rotated(Vector3(0,1,0), rot), Pos * map.WorldScale).translated(Vector3(0,0.1,0))
			
			ChestDat.ChestTransform = Trans
			cellDat.Custom_Data["Chest"] = ChestDat
			#Data.ChestSpawns[Pos] = ChestDat
			tempLayerData.SpawnDeco = false

		else:
			cellDat.AddData("Item", load(it))
			#Data.ItemSpawns[Pos] = it

func GetDebugData(map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	
	for itemPos in get_used_cells():

		var Index = get_cell_atlas_coords(itemPos).x
		
		var text : String = ""
		
		if (map.ItemCaralogue.size() <= Index):
			text = "INVALID!!!!!!!!!!\nSEND HELP"
		else:
			var it : Item = load(map.ItemCaralogue[Index])
			text = it.ItemName
			
		var TextDrawPos = map_to_local(itemPos)
		
		var textSize = ThemeDB.fallback_font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
		TextDrawPos.x -= textSize.x / 2.0
	
		var textData : Dictionary[String, Variant] = {
			"text" : text,
			"color" : DebugStringColor
		}
		
		DebugData["Texts"][TextDrawPos] = textData
		
	return DebugData
