@tool
extends BaseFloorLayer

class_name MazeFloorLayer



func GetLayerType() -> FloorLayer.LayerType:
	return FloorLayer.LayerType.MAZE

func HandleCell(cell : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	var pos = Pos * map.WorldScale
	var rot = GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
	match (index):
	#Wall
		1:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
	#Corner
		2:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
	#Corner
		3:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
		#TJunction
		4:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, rot, pos))
	#Corridor
		5:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
	#Cap
		6:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
	#T section
		7:
			AddWallToData(cell,  GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
	#Door
		8:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		9:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		10:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		11:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		12:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
				
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		13:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
		14:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		15:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)

			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.RIGHT, tempData)
		16:
			AddWallToData(cell, GetWallType(Pos, Vector2.LEFT.rotated(rot), tempData), GetMeshPlecement(Vector2.LEFT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
		17:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
		18:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
		19:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			AddWallToData(cell, GetWallType(Pos, Vector2.RIGHT.rotated(rot), tempData), GetMeshPlecement(Vector2.RIGHT, rot, pos))
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
		20:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.UP, rot, pos))
		21:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
		22:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
		23:
			var dir = Vector2.UP.rotated(rot)
			print(dir)
			print(rot)
			AddWallToData(cell, GetWallType(Pos, dir, tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, rot, pos))
		24:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, rot, pos))
		25:
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
		26:
			AddWallToData(cell, GetWallType(Pos, Vector2.DOWN.rotated(rot), tempData), GetMeshPlecement(Vector2.DOWN, rot, pos))
			
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
		27:
			AddWallToData(cell, GetWallType(Pos, Vector2.UP.rotated(rot), tempData), GetMeshPlecement(Vector2.UP, rot, pos))
			
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
		28:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
		29:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, rot, pos))
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))
		30:
			cell.AddDataArr("DoorWalls", GetMeshPlecement(Vector2.LEFT, rot, pos))
			CheckForDoors(cell, Pos, pos, rot, Vector2i.LEFT, tempData)
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, rot, pos))

func GetMeshPlecement(Dir : Vector2, Rot : float, Pos : Vector3) -> Transform3D:
	var T : Transform3D
	var B = Basis().rotated(Vector3(0,1,0), 0)
	T =  Transform3D(B, Pos)
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

#----------------------------------------------------------------
func separate_into_rooms() -> Array:
	var rooms := []
	var visited := {}
	
	var usedCells = get_used_cells()

	for coord in usedCells:
		if coord in visited:
			continue
		var room = flood_fill(coord, usedCells, visited)
		rooms.append(room)

	return rooms

func SeparateIntoCorridors() -> Array:
	var Corridors := []
	var visited := {}

	var usedCells = get_used_cells()

	for coord in usedCells:
		if coord in visited:
			continue
		var room = flood_fill_ranged(coord, usedCells, 5, visited)
		Corridors.append(room)

	return Corridors

func flood_fill(start: Vector2i, tile_coords: Array, visited: Dictionary) -> Array:
	var room : Array = []
	var stack := [start]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current in visited:
			continue

		visited[current] = true
		room.append(current)

		# Get neighboring tiles (4-directional)
		var neighbors : Array[Vector2i] = [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN
		]

		for neighbor in neighbors:
			if current + neighbor in tile_coords and neighbor + current not in visited and !CantReach(current, neighbor) and !CantReach(current + neighbor, neighbor * -1):
				stack.push_back(neighbor + current)
	
	return room

func flood_fill_ranged(start: Vector2i, tile_coords: Array, dist : float, visited: Dictionary) -> Array:
	var room : Array = []
	var stack := [start]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current in visited:
			continue

		visited[current] = true
		room.append(current)

		# Get neighboring tiles (4-directional)
		var neighbors : Array[Vector2i] = [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN
		]

		for neighbor in neighbors:
			if start.distance_to(current + neighbor) < dist and current + neighbor in tile_coords and neighbor + current not in visited and !CantReach(current, neighbor):
				stack.push_back(neighbor + current)
	
	return room

##Used to declare the blocking direction of each of the MAZE tiles
func CantReach(tilecoords : Vector2, dir : Vector2) -> bool:
	var index = get_cell_atlas_coords(tilecoords).x
	var tilerotation = GetTileRotationRadians(tilecoords)
	var resault : bool
	match index:
		0:
			resault = false
		1:
			var rotatedv = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rotatedv)
		2:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		3:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		4:
			resault = false
		5:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot2) or dir.is_equal_approx(rot1)
		6:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		7:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		8:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		9:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		10:
			var rot1 = Vector2.RIGHT.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		11:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		12:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		13:
			resault = true
		14:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		15:
			resault = true
		16:
			resault = true
		17:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot2) or dir.is_equal_approx(rot1)
		18:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		19:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		20:
			resault = false
		21:
			resault = false
		22:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		23:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		24:
			resault = false
		25:
			resault = false
		26:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		27:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		28:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		29:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		30:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
	return resault
