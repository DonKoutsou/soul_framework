@tool
extends BaseFloorLayer

class_name MazeFloorLayer

func GetLayerType() -> FloorLayer.LayerType:
	return FloorLayer.LayerType.MAZE

func HandleCell(cell : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	var pos = Pos * map.WorldScale
	var rot = deg_to_rad(map.GetTileRotationDegrees(Vector2i(Pos.x, Pos.z), Pos.y))
	var rot2 = map.GetTileRotationRadians(Vector2i(Pos.x, Pos.z), Pos.y)
	match (index):
	#Wall
		1:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
	#Corner
		2:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
	#Corner
		3:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
		#TJunction
		4:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.LEFT, rot, pos))
	#Corridor
		5:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
	#Cap
		6:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
	#T section
		7:
			AddWallToData(cell,  GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
	#Door
		8:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		9:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		10:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		11:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		12:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
				
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		13:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		14:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		15:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)

			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		16:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
		17:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
		18:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
		19:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot2), tempData), GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
		20:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.UP, rot, pos))
		21:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
		22:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
		23:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.LEFT, rot, pos))
		24:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.LEFT, rot, pos))
		25:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
		26:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot2), tempData), GetMeshPlecement(Vector2i.DOWN, rot, pos))
			
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
		27:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot2), tempData), GetMeshPlecement(Vector2i.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
		28:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
		29:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))
		30:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2i.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2i.RIGHT, rot, pos))

func GetMeshPlecement(Dir : Vector2i, Rot : float, Pos : Vector3) -> Transform3D:
	var T : Transform3D
	match Dir:
		Vector2i.RIGHT:
			var B = Basis().rotated(Vector3(0,1,0), Rot + PI)
			T =  Transform3D(B, Pos)
		Vector2i.LEFT:
			var B = Basis().rotated(Vector3(0,1,0), Rot)
			T = Transform3D(B, Pos)
		Vector2i.UP:
			var B = Basis().rotated(Vector3(0,1,0), Rot - PI / 2)
			T = Transform3D(B, Pos)
		Vector2i.DOWN:
			var B = Basis().rotated(Vector3(0,1,0), Rot + PI / 2)
			T = Transform3D(B, Pos)
	return T

func GetWallType(MapPos : Vector3i, Direction : Vector2, tempData : TempGenerationData) -> String:
	var WallType = "Walls"
	if (tempData.Cracks.keys().has(MapPos)):
		if (tempData.Cracks[MapPos].is_equal_approx(Direction)):
			WallType = "BrokenWalls"
	return WallType

func AddWallToData(cell : CellData, WallType : String, Transform : Transform3D) -> void:
	var data = WallData.new()
	data.WallTransform = Transform
	if (WallType == "BrokenWalls"):
		data.Cracked = true
	
	cell.AddDataArr("Walls", data)

func CheckForDoors(cell : CellData, MapPos : Vector3i, LevelPos : Vector3, rot : float, MeshPlecement : Vector2i, tempData : TempGenerationData) -> void:
	if (tempData.Locks.has(MapPos)):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		DoorD.DoorMapPosition = MapPos
		DoorD.LockDat = tempData.Locks[MapPos]
		DoorD.Locked = true
		cell.AddData("Door", DoorD)
		cell.AddDataArr("Locks", GetMeshPlecement(MeshPlecement, rot, LevelPos))
	else: if (tempData.MasterLocks.has(MapPos)):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		cell.AddData("Door", DoorD)
		cell.AddDataArr("MasterLocks", GetMeshPlecement(MeshPlecement, rot, LevelPos))
	else : if (tempData.Blocks.has(MapPos)):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		DoorD.Blocked = true
		cell.AddData("Door", DoorD)
	else : if (cell.HasData("Door")):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		cell.AddData("Door", DoorD)
	else :if (cell.HasData("LightDoor")):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, rot, Vector3i(0,1,0))
		var DoorD = LightDoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		cell.AddData("LightDoor", DoorD)
