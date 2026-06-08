@tool
extends BaseFloorLayer

class_name ItemLayer

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
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
			
			var rot = deg_to_rad(map.GetFloor(Pos.y).GetLayer(FloorLayer.LayerType.LOCKS).GetTileRotationDegrees(Vector2i(Pos.x, Pos.z)))
			var Trans = Transform3D(Basis().rotated(Vector3(0,1,0), rot), Pos * map.WorldScale).translated(Vector3(0,0.1,0))
			
			ChestDat.ChestTransform = Trans
			cellDat.Custom_Data["Chest"] = ChestDat
			#Data.ChestSpawns[Pos] = ChestDat
			tempLayerData.SpawnDeco = false

		else:
			cellDat.AddData("Item", it)
			#Data.ItemSpawns[Pos] = it
