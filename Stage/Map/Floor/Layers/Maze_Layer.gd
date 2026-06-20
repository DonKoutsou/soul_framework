@tool
extends BaseFloorLayer

class_name MazeFloorLayer

func GetLayerType() -> FloorLayer.LayerType:
	return FloorLayer.LayerType.MAZE

func HandleCell(cell : CellData, Pos : Vector3i, map : Map, _tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	#var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	var pos = Pos * map.WorldScale
	var rot = GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
	
	var dat : TileData = get_cell_tile_data(Vector2i(Pos.x, Pos.z))
	
	for wall : Vector2 in dat.get_custom_data("Walls"):
		var wallDir = wall.rotated(rot)
		AddWallToData(cell, GetWallType(Pos, wallDir, tempData), GetMeshPlecement(wall, rot, pos))
	
	for wall : Vector2 in dat.get_custom_data("DoorWalls"):
		cell.AddDataArr("DoorWalls", GetMeshPlecement(wall, rot, pos))
		CheckForDoors(cell, Pos, pos, rot, wall, tempData)
	
	#check if cracks remain in the temp data
	if (tempData.Cracks.has(Pos)):
		printerr("Crack cound not be mapped in {0}".format(Pos))
		
	var centerPointData : PackedVector2Array = GetTileWallData(Vector2i(Pos.x, Pos.z))
	
	var topPoint = Vector2i(Pos.x, Pos.z) + Vector2i(0, -1)
	var topPointData : PackedVector2Array = GetTileWallData(topPoint)
	
	var bottomPoint = Vector2i(Pos.x, Pos.z) + Vector2i(0, 1)
	var bottomPointData : PackedVector2Array = GetTileWallData(bottomPoint)
	
	var leftPoint = Vector2i(Pos.x, Pos.z) + Vector2i(-1, 0)
	var leftPointData : PackedVector2Array = GetTileWallData(leftPoint)
	
	var rightPoint = Vector2i(Pos.x, Pos.z) + Vector2i(1, 0)
	var rightPointData : PackedVector2Array = GetTileWallData(rightPoint)
	
	#check top left corner
	if (!centerPointData.has(Vector2.UP) and !centerPointData.has(Vector2.LEFT)):
		if (leftPointData.has(Vector2.UP) and !leftPointData.has(Vector2.RIGHT)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.UP, 0, pos))
		else: if (topPointData.has(Vector2.LEFT) and !topPointData.has(Vector2.DOWN)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.UP, 0, pos))
		
	# check top right corner
	if (!centerPointData.has(Vector2.UP) and !centerPointData.has(Vector2.RIGHT)):
		if (rightPointData.has(Vector2.UP) and !rightPointData.has(Vector2.LEFT)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, 0, pos))
		else: if (topPointData.has(Vector2.RIGHT) and !topPointData.has(Vector2.DOWN)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.RIGHT, 0, pos))


	# check bottom right corner
	if (!centerPointData.has(Vector2.DOWN) and !centerPointData.has(Vector2.RIGHT)):
		if (rightPointData.has(Vector2.DOWN) and !rightPointData.has(Vector2.LEFT)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, 0, pos))
		else: if (bottomPointData.has(Vector2.RIGHT) and !bottomPointData.has(Vector2.UP)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.DOWN, 0, pos))


	# check bottom left corner
	if (!centerPointData.has(Vector2.DOWN) and !centerPointData.has(Vector2.LEFT)):
		if (leftPointData.has(Vector2.DOWN) and !leftPointData.has(Vector2.RIGHT)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, 0, pos))
		else: if (bottomPointData.has(Vector2.LEFT) and !bottomPointData.has(Vector2.UP)):
			cell.AddDataArr("Corners", GetMeshPlecement(Vector2.LEFT, 0, pos))


func GetTileWallData(tile : Vector2i) -> PackedVector2Array:
	var wallData : PackedVector2Array = []
	if (tile in get_used_cells()):
		var rot = GetTileRotationRadians(tile)
		var dat : TileData = get_cell_tile_data(tile)
		
		for wall : Vector2 in dat.get_custom_data("Walls"):
			wallData.append(wall.rotated(rot).round())
		
		for wall : Vector2 in dat.get_custom_data("DoorWalls"):
			wallData.append(wall.rotated(rot).round())
		
	return wallData

func GetMeshPlecement(Dir : Vector2, Rot : float, Pos : Vector3) -> Transform3D:
	var T : Transform3D
	var B = Basis().rotated(Vector3(0,1,0), -Rot - Dir.angle())
	T =  Transform3D(B, Pos)
	return T

func GetWallType(MapPos : Vector3i, Direction : Vector2, tempData : TempGenerationData) -> String:
	var WallType = "Walls"
	if (tempData.Cracks.keys().has(MapPos)):
		if (tempData.Cracks[MapPos].is_equal_approx(Direction)):
			tempData.Cracks.erase(MapPos)
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
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, -rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		DoorD.DoorMapPosition = MapPos
		DoorD.LockDat = tempData.Locks[MapPos]
		DoorD.Locked = true
		cell.AddData("Door", DoorD)
		cell.AddDataArr("Locks", GetMeshPlecement(MeshPlecement, rot, LevelPos))
	else: if (tempData.MasterLocks.has(MapPos)):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, -rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		cell.AddData("Door", DoorD)
		cell.AddDataArr("MasterLocks", GetMeshPlecement(MeshPlecement, rot, LevelPos))
	else : if (tempData.Blocks.has(MapPos)):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, -rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		DoorD.Blocked = true
		cell.AddData("Door", DoorD)
	else : if (cell.HasData("Door")):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, -rot, Vector3i(0,1,0))
		var DoorD = DoorData.NewData(GetMeshPlecement(MeshPlecement, rot, LevelPos), OppositeLocation)
		cell.AddData("Door", DoorD)
	else :if (cell.HasData("LightDoor")):
		var OppositeLocation = MapPos + Helper.rotate_vector3i(Vector3i.LEFT, -rot, Vector3i(0,1,0))
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
	var cells = get_used_cells()
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
			if (!cells.has(current + neighbor)):
				continue
			if start.distance_to(current + neighbor) < dist and current + neighbor in tile_coords and neighbor + current not in visited and !CantReach(current, neighbor):
				stack.push_back(neighbor + current)
	
	return room

##Used to declare the blocking direction of each of the MAZE tiles
func CantReach(tilecoords : Vector2, dir : Vector2) -> bool:
	var dat : TileData = get_cell_tile_data(tilecoords)
	var tilerotation = GetTileRotationRadians(tilecoords)
	
	var resault : bool = false
	
	for wall : Vector2 in dat.get_custom_data("Walls"):
		var wallDir = wall.rotated(tilerotation)
		if (dir.is_equal_approx(wallDir)):
			resault = true
			break
	
	for wall : Vector2 in dat.get_custom_data("DoorWalls"):
		var wallDir = wall.rotated(tilerotation)
		if (dir.is_equal_approx(wallDir)):
			resault = true
			break
	
	return resault
