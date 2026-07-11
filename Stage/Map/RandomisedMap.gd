@tool
extends Map

class_name RandomisedMap


@export var active : bool = true

##The generated map will not surpass this value
@export var mapSize : Vector2i = Vector2i(40, 40)

##Enables the generation to use patterns stored inside the maze tileset
@export var usePatterns : bool = true

##
@export var guidePaths : bool = true

@export var patternPadding : int = 4

##Seed used for the generation
@export var collapseSeed : int = -1

##Ammount of collapses that happen in one frame
@export var collapseAmmountPerFrame : int = 10

##Used for debug
@export var drawAStar : bool = false

##Only floors set up here will be generated
@export var floorsToGenerate : PackedInt32Array = []

##Kicks of the generation of the map
@export_tool_button("Generate Map") var RegenerateAction = CollapseMap

##Clears tilemaps of any configured tile
@export_tool_button("Clear Map") var clear = CleanMap

@export_tool_button("Run Once") var run = collapseNext

@export var generationSpeed : float = 0.1

@export_file("*.tscn") var Patterns : Array[String]

const NEIGHBOR_DIRECTIONS : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const ROTATIONS : Array[float] = [0, PI/2, PI, -PI/2]

##Current exits, generation uses this to choose next cell to collapse
var currentExits : Array[Vector3i]

##Cells already placed before generation starts or cells spawned by patterns are storred here to avoid changing them
var originalTiles : Array[Vector3i]

##
var cellData : Dictionary[Vector3i, collapseCellData]

#
var tileData : Array[collapseTileData]
var atlasData : Dictionary[int, TileData]

##Keeping track of floors that have already been generated
var generatedFloors : PackedInt32Array = []

##Currently generating floor
var currentFloor : int = 0


var rooms : Array

var aStar : MapGeneratorAstar

var r : RandomNumberGenerator

var finised : bool = false

var PlacedRooms : Array[PackedVector3Array]
var PlacedRoomsWithNoExit : Array
var originalRooms
var collapse_history : Array[Vector3i]
var mandatoryCollapses : Array[Vector2i]

enum CELL_ABORT_REASON{
	NONE,
	NO_OWNER_FOUND,
	ROOM_HAS_NO_EXITS,
	ROOM_GOT_SECLUDED,
}

func _ready() -> void:
	super()
	if (Engine.is_editor_hint()):
		finised = true
	
	aStar = MapGeneratorAstar.new()
	add_child(aStar)

#----------------------------------------------------
var workerID = -1
func LoadMapData(MData : MapData) -> void:
	Data = MData
	collapseSeed = Data.MetaData["GenerationSeed"]
	CleanMap()
	#CollapseMap()
	workerID = WorkerThreadPool.add_task(CollapseMap)

#----------------------------------------------------
func LoadingProgressed(newProgress : float) -> void:
	LoadingUpdate.emit(newProgress * 100.0)

#----------------------------------------------------
func loadFinished() -> void:
	if (workerID > 0):
		WorkerThreadPool.wait_for_task_completion(workerID)
	loaded = true
	LoadingFinised.emit()
	

#---------------------------------------------
func generate_maze(spawnMons : bool) -> void:
	if (Engine.is_editor_hint()):
		if (finised):
			super(spawnMons)
			Data.MetaData["GenerationSeed"] = r.seed
			return
	else:
		CleanMap()
		CollapseMap()
		super(spawnMons)
		Data.MetaData["GenerationSeed"] = r.seed

#---------------------------------------------
var i : float = 0.1
func _process(delta: float) -> void:
	if (!active or finised):
		return
	if (Engine.is_editor_hint()):
		i -= delta
		if (i > 0):
			return
		i = generationSpeed
		collapseNext()

#-------------------------------------------------------------
func collapseNext() -> void:
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	if (currentExits.size() == 0):
		
		generatedFloors.append(currentFloor)
		
		var used = layer.get_used_cells()
		#used.sort()
		
		
		for g in aStar.Astar.get_point_count():
			var pointPos =  aStar.Astar.get_point_position(g)
			if (pointPos.y != currentFloor):
				continue
				
			var twoDPos = Helper.Vector3ITo2(pointPos)
			if (!used.has(twoDPos)):
				aStar.Astar.set_point_disabled(g)
		
		if (generatedFloors.size() < floorsToGenerate.size()):
			_progress_floor()
		else:
			_add_finishing_touches()
			finised = true
			call_deferred("loadFinished")
			
		if (Engine.is_editor_hint()):
			queue_redraw()
		return
	
	for g in cellData:
		if (g.y != currentFloor):
			continue
		var cell = cellData[g]
		cell.StoreState()
		
	collapse_history.clear()
	originalRooms = rooms.duplicate()
	var prevMandatory = mandatoryCollapses
	
	for v in collapseAmmountPerFrame:
		#Get possible cells that we could collapse
		var possible : Array[Vector3i]
		if (mandatoryCollapses.size() > 0):
			possible.append(Helper.Vector2iTo3(mandatoryCollapses.pop_back(), currentFloor))
		else:
			possible = GetPossibleCollapses()
		
		if (possible.size() == 0):
			break
		
		var randomIndex = r.randi_range(0, possible.size() - 1)
		var cellPos = possible[randomIndex]
		var TwoDcellPos = Helper.Vector3ITo2(cellPos)
		
		CellCollapsed(TwoDcellPos)
		
		var collapsed : Array[Vector2i]
		PropagateContrains(TwoDcellPos, collapsed)
		collapsed.push_front(TwoDcellPos)
		
		var abortReason : CELL_ABORT_REASON = GetAbortReason(collapsed)
			
		if (abortReason != CELL_ABORT_REASON.NONE):
			#print("broken room {0}".format([var_to_str(room)]))
			rooms = originalRooms
			
			RevertCollapses()
			
			collapse_history.clear()
			
			for g in cellData:
				if (g.y != currentFloor):
					continue
				cellData[g].RevertState()

			mandatoryCollapses = prevMandatory
			
			print("CELL ABORTED | REASON ---> {0}".format([CELL_ABORT_REASON.keys()[abortReason]]))

			break
			

	if (Engine.is_editor_hint()):
		queue_redraw()

#-----------------------------------------------------
func GetAbortReason(collapsed : Array[Vector2i]) -> CELL_ABORT_REASON:
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	var abortReason : CELL_ABORT_REASON = CELL_ABORT_REASON.NONE
	
	for col in collapsed:
		var ownerRooms : Array
		#find the owner room of this cell
		for room : Array in rooms:
			for neighbor in NEIGHBOR_DIRECTIONS:
				if (room.has(col + neighbor) and !layer.CantReach(col, neighbor, true)):
					ownerRooms.append(room)
					break
		#if multiple owners exist we need to merge them since the cell bridges them.
		if (ownerRooms.size() > 1):
			var combined : Array
			for g in ownerRooms:
				combined.append_array(g)
				rooms.erase(g)
			rooms.append(combined)
			combined.append(col)
			print("Combined rooms")
		else: if (ownerRooms.size() > 0):
			ownerRooms[0].append(col)
		else:
			abortReason = CELL_ABORT_REASON.NO_OWNER_FOUND
	
	if (abortReason == CELL_ABORT_REASON.NONE and rooms.size() > 1 + PlacedRoomsWithNoExit.size()):
		
		#if multiple rooms exist we need to check if they have exits, if not we take back this collapse
		for room in rooms:
			
			if (PlacedRoomsWithNoExit.has(room)):
				continue
			
			var exits : Array[Vector2i] = []
			#if room has exit we need to check if this exit communicates with another room
			
			if (RoomHasExit(room, layer, exits)):
				var haseAccessToAllRooms = true
				
				for roomToCheck in rooms:
					if (PlacedRoomsWithNoExit.has(roomToCheck)):
						continue
					if (roomToCheck == room):
						continue
					var start = Helper.Vector2iTo3(room[0], currentFloor)
					var startID = aStar.Astar.get_closest_point(start)
					var destination = Helper.Vector2iTo3(roomToCheck[0], currentFloor)
					var distinationID = aStar.Astar.get_closest_point(destination)
					
					var path = aStar.Astar.get_point_path(startID, distinationID)
					if (path.size() == 0):
						haseAccessToAllRooms = false
						break
					
					var lastPoint = path[path.size() - 1]
					if (Vector3i(lastPoint) != destination):
						haseAccessToAllRooms = false
						break
				
				if (!haseAccessToAllRooms):
					abortReason = CELL_ABORT_REASON.ROOM_HAS_NO_EXITS
					break
				continue
			else:
				abortReason = CELL_ABORT_REASON.ROOM_HAS_NO_EXITS
				break
			
	return abortReason
	
#---------------------------------------------
##Returns cells with the lowest entropy
func GetPossibleCollapses() -> Array[Vector3i]:
	var possible : Array[Vector3i]
	var currentEntropy = INF
	if (currentExits.size() == 0):
		return possible
		
	for g in cellData:
		if (!currentExits.has(g)):
			continue

		var cell = cellData[g]
		if (cell.collapsed):
			continue
		var cellEntropy = cell.GetEntropy(atlasData)

		if cellEntropy < currentEntropy:
			possible.clear()
			currentEntropy = cellEntropy
			#nextToCollapse = g
			possible.append(g)
		else: if cellEntropy == currentEntropy:
			possible.append(g)
	return possible

#---------------------------------------------
##Checks if the this room is in contact with any of the exits
func RoomHasExit(room : Array, layer : MazeFloorLayer, exits : Array[Vector2i]) -> bool:
	for g in currentExits:
		var TwoDPos = Helper.Vector3ITo2(g)
		for neighbor in NEIGHBOR_DIRECTIONS:
			if (room.has(TwoDPos + neighbor)):
				if (layer.CantReach(TwoDPos + neighbor, -neighbor, true)):
					continue
				exits.append(TwoDPos)
	return exits.size() > 0

#---------------------------------------------
func GetRandomBorder(room : Array) -> Vector2i:
	for tile in room:
		for neighbor in NEIGHBOR_DIRECTIONS:
			var neighborPos = tile + neighbor
			if (!room.has(neighborPos)):
				return tile
	return Vector2i.MAX

#------------------------------------------------
##Resets state of cell
func RefillTile(tilePos : Vector2i, cell : collapseCellData) -> void:
	cell.possibleTiles.clear()
	cell.collapsed = false
	for tile in tileData:
		
		#If we are on map edge check to make sure we have wall facing edge
		if (tilePos.x == 0):
			if (!HasWallInDirection(tile, Vector2(-1,0))):
				continue
		else: if (tilePos.x == mapSize.x - 1):
			if (!HasWallInDirection(tile, Vector2(1,0))):
				continue
		if (tilePos.y == 0):
			if (!HasWallInDirection(tile, Vector2(0, -1))):
				continue
		else: if (tilePos.y == mapSize.y - 1):
			if (!HasWallInDirection(tile, Vector2(0, 1))):
				continue
		
		cell.possibleTiles.append(tile)
		
#----------------------------------------------------
#debug
func _draw() -> void:
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	var cols : Array[Color] = [Color(1,0,0), Color(0,1,0), Color(0,0,1), Color(0.85, 0.444, 0.0, 1.0), Color(0.736, 1.0, 0.406, 1.0)]
	for roomIndex in rooms.size():
		var col = cols[wrap(roomIndex, 0, cols.size())]
		for tile in rooms[roomIndex]:
			var pos = layer.map_to_local(tile) + Vector2(0, currentFloor * 320)
			draw_circle(pos, 2, col)
	
	for g in currentExits:
		var twoD = Helper.Vector3ITo2(g)
		draw_circle(layer.map_to_local(twoD) + Vector2(0, g.y * 320), 4, Color(0.387, 0.002, 0.876, 1.0))
	
	for g in cellData:
		var cell = cellData[g]
		#if (cell.collapsed):
			#continue

		var text = var_to_str(cellData[g].possibleTiles.size())
		
		var stringSize = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2) / 3.0
		#stringSize.y *= -1
		
		draw_string(ThemeDB.fallback_font, layer.map_to_local(Helper.Vector3ITo2(g)) + Vector2(0, g.y * 320) - stringSize, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)

	if (drawAStar):
		aStar.queue_redraw()
		
	super()
#---------------------------------------------------
##Clears all tilemap layers in map
func CleanMap() -> void:
	for g in PropParent.get_children():
		g.queue_free()
	for fl in Floors:
		for layer : TileMapLayer in fl.GetLayers():
			layer.clear()

#----------------------------------------------------
##Starts the generation of the map
func CollapseMap() -> void:
	finised = false
	generatedFloors.clear()
	originalTiles.clear()
	aStar.Clear()
	PlacedRooms.clear()
	PlacedRoomsWithNoExit.clear()
	currentFloor = floorsToGenerate[0]
	Props.clear()
	MegaProps.clear()
	
	cellData = {}
	
	_update_atlas_data()
	
	r = RandomNumberGenerator.new()
	#-1 is default seed value
	if (collapseSeed != -1):
		r.seed = collapseSeed
		print("[[MAP GENERATION STARTED]] with configured seed : {0}".format([collapseSeed]))
	else:
		r.randomize()
		print("[[MAP GENERATION STARTED]] with new random seed :{0}".format([r.seed]))
	
	if (usePatterns):
		_place_patterns()
	
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	_init_layer(layer)
	
	if (Engine.is_editor_hint()):
		queue_redraw()
	else:
		while(!finised):
			collapseNext()

#---------------------------------------------
##Runs after map is ready to add any details, enemies etc...
func _add_finishing_touches() -> void:
	var spawnFloorIndex = floorsToGenerate[r.randi_range(0, floorsToGenerate.size() - 1)]
	var spawnFloor = GetFloor(spawnFloorIndex)
	var spawnmapInfoLayer = spawnFloor.GetLayer(FloorLayer.LayerType.MAP_INFO)
	var spawnmazeLayer = spawnFloor.GetLayer(FloorLayer.LayerType.MAZE)
	var spawnFloorUsed = spawnmazeLayer.get_used_cells()
	spawnFloorUsed.sort()
	
	var spawnIndex = r.randi_range(0, spawnFloorUsed.size() - 1)
	var spawnPos = spawnFloorUsed[spawnIndex]
	var triDSpawnPos = Helper.Vector2iTo3(spawnPos, spawnFloorIndex)
	
	var spawnPointID = aStar.Astar.get_closest_point(triDSpawnPos)
	
	spawnmapInfoLayer.set_cell(spawnPos, 0, Vector2i(14,0))
	
	var possibleDoors : Array[Vector3i]
	var possibleLockedDoors : Array[Vector3i]
	
	var RoomToLock : Array[PackedVector3Array]
	var availableRoomsToLock = PlacedRooms.duplicate()
	
	while RoomToLock.size() < 3 and availableRoomsToLock.size() > 0:
		var randIndex = r.randi_range(0, availableRoomsToLock.size() - 1)
		var randomRoom = availableRoomsToLock.pop_at(randIndex)
		
		if (randomRoom.has(triDSpawnPos)):
			continue
			
		
		var doors : PackedVector3Array = []
		var doorDirs : PackedVector2Array = []
		for cellPos : Vector3i in randomRoom:
			var cell : collapseCellData = cellData[cellPos]
			var tile : collapseTileData = cell.possibleTiles[0]
			var dat : TileData = atlasData[tile.tileIndex]
			if (dat.get_custom_data("DoorWalls").size() == 1):
				doors.append(cellPos)
				doorDirs.append(dat.get_custom_data("DoorWalls")[0].rotated(tile.tileRotation))
				
		if (doors.size() == 1):
			var doorPos = doors[0]
			var doorDir = doorDirs[0]
			
			var oppositeDoor = Vector3i(doorPos) + Vector3i(doorDir.x, 0, doorDir.y)
			var oppositeCell : collapseCellData = cellData[oppositeDoor]
			var oppositeTile = oppositeCell.possibleTiles[0]
			var oppositeDat : TileData = atlasData[oppositeTile.tileIndex]
			
			if (oppositeDat.get_custom_data("DoorWalls").size() > 1):
				continue

			possibleLockedDoors.append(doorPos)
			possibleLockedDoors.append(oppositeDoor)
			
			var point1 = aStar.Astar.get_closest_point(doorPos)
			var point2 = aStar.Astar.get_closest_point(oppositeDoor)
			aStar.Astar.disconnect_points(point1, point2)
			
			var fl = GetFloor(doorPos.y)
			var itemLayer = fl.GetLayer(FloorLayer.LayerType.ITEMS)
			
			var randomTileIndex = r.randi_range(0, randomRoom.size() - 1)
			var randomTile = Helper.Vector3ITo2(randomRoom[randomTileIndex])
			itemLayer.set_cell(randomTile, 0, Vector2i(0,0))
		
			RoomToLock.append(randomRoom)
		#for cellLoc in RoomToLock:
			#var cell = cellData.
	
	var PlacedKeys : int = 0
	var availableRoomsToPutKey = PlacedRooms.duplicate()
	#find place to add keys
	while PlacedKeys < RoomToLock.size() and availableRoomsToPutKey.size() > 0:
		var randIndex = r.randi_range(0, availableRoomsToPutKey.size() - 1)
		var randomRoom = availableRoomsToPutKey.pop_at(randIndex)
		
		var randomTileIndex = r.randi_range(0, randomRoom.size() - 1)
		var randomPos : Vector3 = randomRoom[randomTileIndex]
		
		var randomTileID = aStar.Astar.get_closest_point(randomPos)
		
		var path = aStar.Astar.get_id_path(spawnPointID ,randomTileID)
		if (path.has(randomTileID)):
			var randomTile = Helper.Vector3ITo2(randomPos)
			
			var fl = GetFloor(randomPos.y)
			var itemLayer = fl.GetLayer(FloorLayer.LayerType.ITEMS)
			itemLayer.set_cell(randomTile, 0, Vector2i(1,0))
			PlacedKeys += 1
	
	#find possible doors
	while possibleDoors.size() < 20:
		var floorIndex = generatedFloors[r.randi_range(0, generatedFloors.size() - 1)]
		
		var randomPos = Vector3i(r.randi_range(0, mapSize.x -1), floorIndex, r.randi_range(0, mapSize.y - 1))
		if (!cellData.has(randomPos) or possibleLockedDoors.has(randomPos)):
			continue
		var randomCell : collapseCellData = cellData[randomPos]
		if (randomCell.possibleTiles.size() == 0):
			continue
		var randomTile = randomCell.possibleTiles[0]
		var dat : TileData = atlasData[randomTile.tileIndex]
		var doorAmm = dat.get_custom_data("DoorWalls").size()
		
		if (doorAmm == 1):
			var fl = GetFloor(floorIndex)
			var InfoLayer : TileMapLayer = fl.GetLayer(FloorLayer.LayerType.MAP_INFO)
			var infoUsed = InfoLayer.get_used_cells()
			
			#find opposite door
			var randomDoor = dat.get_custom_data("DoorWalls")[r.randi_range(0, doorAmm - 1)].rotated(randomTile.tileRotation)
			var oppositeDoor = randomPos + Vector3i(randomDoor.x, 0, randomDoor.y)
			var oppositeCell : collapseCellData = cellData[oppositeDoor]
			var oppositeTile = oppositeCell.possibleTiles[0]
			var oppositeDat : TileData = atlasData[oppositeTile.tileIndex]
			
			if (oppositeDat.get_custom_data("DoorWalls").size() > 1):
				continue
			
			if (!infoUsed.has(Helper.Vector3ITo2(randomPos)) and !infoUsed.has(Helper.Vector3ITo2(oppositeDoor))):
				possibleDoors.append(randomPos)
				possibleDoors.append(oppositeDoor)

	for g in possibleDoors:
		var f = GetFloor(g.y)
		var InfoLayer = f.GetLayer(FloorLayer.LayerType.MAP_INFO)
		InfoLayer.set_cell(Helper.Vector3ITo2(g), 0, Vector2i(26,0))
	
	for g in possibleLockedDoors:
		var f = GetFloor(g.y)
		var InfoLayer = f.GetLayer(FloorLayer.LayerType.LOCKS)
		InfoLayer.set_cell(Helper.Vector3ITo2(g), 0, Vector2i(0,0))

	for fl in floorsToGenerate:
		var f = GetFloor(fl)
		var mazeLayer = f.GetLayer(FloorLayer.LayerType.MAZE)
		var monsterLayer = f.GetLayer(FloorLayer.LayerType.MONSTERS)
		var itemLayer = f.GetLayer(FloorLayer.LayerType.ITEMS)
		var mapInfoLayer = f.GetLayer(FloorLayer.LayerType.MAP_INFO)
		var mapInfo2Layer = f.GetLayer(FloorLayer.LayerType.MAP_INFO2)
		
		var restricted : Array[Vector2i] = []
		restricted.append_array(itemLayer.get_used_cells())
		restricted.append_array(mapInfoLayer.get_used_cells())
		restricted.append_array(mapInfo2Layer.get_used_cells())
		
		var used = mazeLayer.get_used_cells()
		used = used.filter(IsIncluded.bind(restricted))
		used.sort()
		
		for g in (mapSize.x * mapSize.y) / 100:
			var monIndex = r.randi_range(0, used.size() - 1)
			monsterLayer.set_cell(used[monIndex], 0, Vector2i(0,0))
		
		var usedInfo = mapInfoLayer.get_used_cells()
		#add floor connections
		for cell : Vector2i in usedInfo:
			var atlas = mapInfoLayer.get_cell_atlas_coords(cell)
			if (atlas.x == 17):
				aStar.Connect(Helper.Vector2iTo3(cell, fl), Helper.Vector2iTo3(cell, fl + 1))

func IsIncluded(element : Vector2i, array : Array[Vector2i]) -> bool:
	return !array.has(element)

#-------------------------------------------------------------
##Progresses the generation to the next floor
func _progress_floor() -> void:
	#store layers of finished floor
	var lastFloor = GetFloor(currentFloor)
	var lastLayer : MazeFloorLayer = lastFloor.GetLayer(FloorLayer.LayerType.MAZE)
	var lastInfoLayer = lastFloor.GetLayer(FloorLayer.LayerType.MAP_INFO)
	
	var used = lastLayer.get_used_cells()
	used.sort()

	currentFloor += 1
	call_deferred("LoadingProgressed", float(generatedFloors.size()) / floorsToGenerate.size())
	
	#store layers of current floor
	var f = GetFloor(currentFloor)
	var l : MazeFloorLayer = f.GetLayer(FloorLayer.LayerType.MAZE)
	var InfoLayer = f.GetLayer(FloorLayer.LayerType.MAP_INFO)
	
	#we need to make sure to not place the stairs connected two already connected rooms
	
	#get existing stairs on current floor
	var stairs : Array[Vector2i]
	for cell in lastInfoLayer.get_used_cells():
		var atlas : Vector2i = lastInfoLayer.get_cell_atlas_coords(cell)
		if (atlas.x == 17):
			stairs.append(cell)
	
	var lastRooms = lastLayer.separate_into_rooms()
	var currentRooms = l.separate_into_rooms()
	
	#find the rooms each stairs are connecting
	for stair in stairs:
		var lastRoom : Array
		for room in lastRooms:
			if (room.has(stair)):
				lastRoom = room
				break
		var currentRoom : Array
		for room in currentRooms:
			if (room.has(stair)):
				currentRoom = room
				break
		if (lastRoom == null or currentRoom == null):
			continue
		#once we find the connected rooms, we need to find their intercecting points and remove them from the array that we will pick the ladder from
		for cell in lastRoom:
			if (currentRoom.has(cell)):
				used.erase(cell)
	
	var currentUsed = l.get_used_cells()
	
	var randomCell = used[r.randi_range(0, used.size() - 1)]
	
	lastInfoLayer.set_cell(randomCell, 0, Vector2i(17, 0))
	
	InfoLayer.set_cell(randomCell, 0, Vector2i(18, 0))
	
	if (!currentUsed.has(randomCell)):
		var availableWeights : PackedFloat32Array = GetTileWeights(randomCell, true)

		var picked = r.rand_weighted(availableWeights)
		
		var pickedTile : collapseTileData = tileData[picked]

		#mandatoryCollapses.append(randomCell)
		#CellCollapsed(randomCell)
		
		l.set_cell(randomCell, 10, Vector2i(pickedTile.tileIndex, 0), Helper.GetTileAltFromRotation(pickedTile.tileRotation))
		
	_init_layer(l)
	
		
	#Connect the 2 floors
	
	

#---------------------------------------------------
#Initialise the provided layer
func _init_layer(layer : MazeFloorLayer) -> void:
	
	#store any existing cells in map
	var Usedcells = layer.get_used_cells()
	Usedcells.sort()
	
	#if we dont have ant used, add a random one to initialise the collapse from there
	if (Usedcells.size() == 0):
		var randomCell = Vector2i(r.randi_range(0, mapSize.x - 1), r.randi_range(0, mapSize.y - 1))

		var availableWeights : PackedFloat32Array = GetTileWeights(randomCell)
		
		var picked = r.rand_weighted(availableWeights)
		
		var pickedTile : collapseTileData = tileData[picked]
		
		layer.set_cell(randomCell, 10, Vector2i(pickedTile.tileIndex, 0), Helper.GetTileAltFromRotation(pickedTile.tileRotation))
		Usedcells.append(randomCell)
		
	for cell in Usedcells:
		var positionCellData = collapseCellData.new()
		
		originalTiles.append(Helper.Vector2iTo3(cell, currentFloor))
		
		var dat = collapseTileData.new()
		dat.tileIndex = layer.get_cell_atlas_coords(cell).x
		dat.tileRotation = layer.GetTileRotationRadians(cell)
		
		positionCellData.possibleTiles.append(dat)
		positionCellData.collapsed = true
		
		cellData[Helper.Vector2iTo3(cell, currentFloor)] = positionCellData
	
	var star = layer.GetAStar(currentFloor, mapSize)
	
	PlacedRoomsWithNoExit.clear()
	rooms = layer.separate_into_islands()
	
	for room in rooms:
		
		var TriDRoom : PackedVector3Array = []
		for tileIndex in room.size():
			var triD = Helper.Vector2iTo3(room[tileIndex], currentFloor)
			TriDRoom.append(triD)
		
		PlacedRooms.append(TriDRoom)

	var exits = layer.find_exits()
	currentExits.clear()
	
	for g in exits:
		var ex = Helper.Vector2iTo3(g, currentFloor)
		if (!currentExits.has(ex)):
			currentExits.append(ex)
	
	for room in rooms:
		if (!RoomHasExit(room, layer, [])):
			PlacedRoomsWithNoExit.append(room)
	
	if (guidePaths and Usedcells.size() > 1):
		#get a path from each exit to another
		var paths : PackedVector3Array = []
		
		for exit in currentExits:
			for exit2 in currentExits:
				var point1 = star.get_closest_point(exit)
				var point2 = star.get_closest_point(exit2)
				var path = star.get_point_path(point1, point2)
				paths.append_array(path)
		
		for point in star.get_point_count():
			var pointPos = star.get_point_position(point)
			if (!paths.has(pointPos) and !Usedcells.has(Helper.Vector3ITo2(pointPos))):
				star.set_point_disabled(point)
	
		#Initialise all tiles
		for x in mapSize.x:
			for y in mapSize.y:
				var pos = Vector2i(x, y)
				var TriDpos = Helper.Vector2iTo3(pos, currentFloor)
				
				if (cellData.has(TriDpos) or Vector3(TriDpos) not in paths):
					continue
				
				var positionCellData = collapseCellData.new()
				
				RefillTile(pos, positionCellData)
				cellData[TriDpos] = positionCellData
		
		for TriDpos in cellData:
			if (TriDpos.y != currentFloor):
				continue
			var cell = cellData[TriDpos]
			
			UpdateConstrains(cell, Helper.Vector3ITo2(TriDpos))
	
	else:
		#Initialise all tiles
		for x in mapSize.x:
			for y in mapSize.y:
				var pos = Vector2i(x, y)
				var TriDpos = Helper.Vector2iTo3(pos, currentFloor)
				
				if (cellData.has(TriDpos)):
					continue
				
				var positionCellData = collapseCellData.new()
				
				RefillTile(pos, positionCellData)
				cellData[TriDpos] = positionCellData
	
	#Propagate any existing contrains
	var collapsed : Array[Vector2i]
	for cell in Usedcells:
		PropagateContrains(cell, collapsed)
	
	
	aStar.Add(star)
	


#-----------------------------------------------------
##Places parrents to all floors before generation starts
func _place_patterns() -> void:
	var paterns : Array[Map_Pattern]
	#check what patterns we can actually place, if pattern has more floors than we do skip it
	for pat in Patterns:
		var patternFile : PackedScene = load(pat)
		var loadedPattern : Map_Pattern = patternFile.instantiate()
		
		var patternExtents = loadedPattern.GetFloorExtents()
		var minFloor = patternExtents.x
		var maxFloor = patternExtents.y
		var floorRange = abs(maxFloor - minFloor)
		
		if (floorRange <= GetFloorAmm()):
			#add_child(loadedPattern)
			loadedPattern.StoreLayers()
			loadedPattern.StorePatterns()
			loadedPattern.StoreProps()
			
			paterns.append(loadedPattern)
		else:
			loadedPattern.queue_free()
	
	
	while (paterns.size() > 0):
		#pick random pattern
		var index = r.randi_range(0, paterns.size() - 1)
		var pickedPattern : Map_Pattern = paterns[index]
		
		
		var patternExtents = pickedPattern.GetFloorExtents()
		var minFloor = patternExtents.x
		var maxFloor = patternExtents.y
		
		var allowedFloors : Array[int] = []
		var floorIndexes : Array[int] = GetFloorIndexes()
		
		#store at wich floors this pattern can be placed
		for g in floorIndexes:
			if (floorIndexes.has(g + minFloor) and floorIndexes.has(g + maxFloor)):
				allowedFloors.append(g)

		#pick one of the allowed floors randomly
		var pickedFloorIndex = allowedFloors[r.randi_range(0, allowedFloors.size() - 1)]
		var randomPosition = Vector2i(r.randi_range(1 + patternPadding, mapSize.x - 1 - patternPadding - pickedPattern.GetSize().x), r.randi_range(1 + patternPadding, mapSize.y - 1 - patternPadding - pickedPattern.GetSize().y))
		
		#pick a random rotation
		var rot = r.randi_range(0, 3)
		
		#try to find a place
		var maxTries : int = 5
		var foudPlace = can_place_map_pattern(pickedPattern, randomPosition, pickedFloorIndex, rot)
		while (!foudPlace and maxTries > 0):
			randomPosition = Vector2i(r.randi_range(1 + patternPadding, mapSize.x - 1 - patternPadding - pickedPattern.GetSize().x), r.randi_range(1 + patternPadding, mapSize.y - 1 - patternPadding - pickedPattern.GetSize().y))
			pickedFloorIndex = allowedFloors[r.randi_range(0, allowedFloors.size() - 1)]
			rot = r.randi_range(0, 3)
			foudPlace = can_place_map_pattern(pickedPattern, randomPosition, pickedFloorIndex, rot)
			maxTries -= 1
		
		
		if (foudPlace):
			pickedPattern.MaxPlacements -= 1

			var patternSize = pickedPattern.GetSize()
			for patternFloorIndex in pickedPattern.GetFloorIndexes():
				var fl = GetFloor(pickedFloorIndex + patternFloorIndex)
				fl.ApplyPattern(pickedPattern, patternFloorIndex, randomPosition, rot)
			
			
			var radiantRot = rot * (PI / 2)
			var props = pickedPattern.GetProps()
			for prop in props:
				for data : MeshData in props[prop]:
					var mesh : MeshInstance3D = MeshInstance3D.new()
					mesh.mesh = prop
					var rotatedPoint = Helper.rotate_point(Helper.Vector3To2(data.Transform.origin / Vector3(WorldScale)), Vector2(0,0), patternSize.x + 1, patternSize.y + 1, rot)
					
					var newOrigin = Helper.Vector2To3(rotatedPoint * Helper.Vector3To2(WorldScale), data.Transform.origin.y)
					var trans = Transform3D(Basis(), newOrigin).translated_local(Vector3(Helper.Vector2iTo3(randomPosition, pickedFloorIndex) * WorldScale))
					trans.basis = Basis(Vector3(0, 1, 0), -radiantRot) * data.Transform.basis

					mesh.transform = trans
					
					PropParent.call_deferred("add_child", mesh)
		
		if (!foudPlace or pickedPattern.MaxPlacements == 0):
			#print("Cant place pattern on floor {0}".format([pickedFloorIndex]))
			pickedPattern.queue_free()
			paterns.remove_at(index)


#-----------------------------------------------
##Collect all data from tileset and store them in atlasData
func _update_atlas_data() -> void:
	atlasData.clear()

	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	#var emptyData : Dictionary = {
		#"Walls" : NEIGHBOR_DIRECTIONS,
		#"DoorWalls" : [],
		#"CollapseWeight" : 10
	#}
#
	#atlasData[-1] = emptyData
	
	var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)
	for tileIndex : int in layer.tile_set.get_source(10).get_tiles_count():
		var dat : TileData = tileAtlas.get_tile_data(Vector2i(tileIndex, 0), 0)
		atlasData[tileIndex] = dat
	
	tileData.clear()
	for tileIndex : int in atlasData:
		for rot in ROTATIONS:
			var dat = collapseTileData.new()
			dat.tileIndex = tileIndex
			dat.tileRotation = rot
			
			tileData.append(dat)

#-----------------------------------------------
##Converts tileData to a dictionary
func TileDataToDict(dat : TileData) -> Dictionary:
	var dataDict : Dictionary = {
			"Walls" : dat.get_custom_data("Walls"),
			"DoorWalls" : dat.get_custom_data("DoorWalls"),
			"CollapseWeight" : dat.probability
		}
	return dataDict

#-----------------------------------------------
##Checks if pattern can be placed
func can_place_map_pattern(mapPattern : Map_Pattern, patternPosition: Vector2i, f : int, rot : int) -> bool:
	var canPlace : bool = true
	for floorIndex : int in mapPattern.GetFloorIndexes():
		var fl = GetFloor(f + floorIndex)
		if (fl == null):
			print("Cant find floor {0}".format([f + floorIndex]))

		var pattern : TileMapPattern = Helper.rotate_pattern(mapPattern.GetPattern(FloorLayer.LayerType.MAZE, floorIndex), rot, mapPattern.GetSize())
		
		if (!fl.can_place_pattern(pattern, patternPosition, mapSize)):
			canPlace = false
			break
	
	return canPlace


#-----------------------------------------------
##Called when a cell collapses meaning its possibilities have reached 1
func CellCollapsed(cellPos : Vector2i) -> void:
	var TriDPos = Helper.Vector2iTo3(cellPos, currentFloor)
	var cell = cellData[TriDPos]
	var availableWeights : PackedFloat32Array
	
	for tile : collapseTileData in cell.possibleTiles:
		availableWeights.append(atlasData[tile.tileIndex].probability)
	
	var picked = r.rand_weighted(availableWeights)
	
	var pickedTile : collapseTileData = cell.possibleTiles[picked]
	
	cell.possibleTiles.clear()
	cell.possibleTiles.append(pickedTile)
	cell.collapsed = true

	if(pickedTile.tileIndex == -1):
		print("Wrong pick, something went wrong")
		return
	
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	layer.set_cell(cellPos, 10, Vector2i(pickedTile.tileIndex, 0), Helper.GetTileAltFromRotation(pickedTile.tileRotation))
	
	currentExits.erase(TriDPos)
	
	var newExits = layer.GetNeighboringExits(cellPos)
	#Update Astar
	var collapsedCellID = aStar.Astar.get_closest_point(TriDPos)
	if (Vector3(TriDPos) != aStar.Astar.get_point_position(collapsedCellID)):
		print("issue, was looking for point in position {0} and got point in position {1}".format([var_to_str(TriDPos), var_to_str(aStar.Astar.get_point_position(collapsedCellID))]))
		
		
	var used = layer.get_used_cells()
	#for each of our new exits
	for dir in NEIGHBOR_DIRECTIONS:
		var neightborPos = cellPos + dir
		if (newExits.has(neightborPos)):
			continue
		
		if (used.has(neightborPos)):
			if (!layer.CantReach(cellPos, dir, true)):
				continue
			
		
		var exitPointID = aStar.Astar.get_closest_point(Helper.Vector2iTo3(neightborPos, currentFloor))
		aStar.Astar.disconnect_points(collapsedCellID, exitPointID)
		
	for exit in newExits:
		var TriDExis = Helper.Vector2iTo3(exit, currentFloor)
		
		#if it already is an exit we just connect our collapsed cell to it
		var exitPointID = aStar.Astar.get_closest_point(TriDExis)
		aStar.Astar.connect_points(collapsedCellID, exitPointID)

		if (Vector3(TriDExis) != aStar.Astar.get_point_position(exitPointID)):
				print("issue, was looking for point in position {0} and got point in position {1}".format([var_to_str(TriDExis), var_to_str(aStar.Astar.get_point_position(exitPointID))]))
		
		var exitCell = cellData[TriDExis]
		
		if (!exitCell.collapsed and !currentExits.has(TriDExis)):
			currentExits.append(TriDExis)
	
	collapse_history.append(TriDPos)

#-------------------------------------------
##Returns the positions of the neighboring cells
func GetCellNeighbors(cell : Vector2i) -> Array[Vector2i]:
	var neighbors : Array[Vector2i] = []
	
	for g in NEIGHBOR_DIRECTIONS:
		neighbors.append(cell + g)
	
	return neighbors

#-------------------------------------------
##Reverts all colapses done in this frame and stored inside collapse_history
func RevertCollapses() -> void:
	for collapseIndex in range(collapse_history.size() -1, -1, -1):
		
		var collapse = collapse_history[collapseIndex]
		if (collapse.y != currentFloor):
			continue
		
		_revert(collapse)
			
	for collapse in collapse_history:
		var cell = cellData[collapse]
		var TwoDcellPos = Helper.Vector3ITo2(collapse)
		UpdateConstrains(cell, TwoDcellPos)
		#print("revered {0}. new constaint amm {1}".format([collapse, cell.possibleTiles.size()]))

#-------------------------------------------
func _revert(collapse : Vector3i) ->void:
		
	var TwoDcellPos = Helper.Vector3ITo2(collapse)
	
	var layer : MazeFloorLayer = GetFloor(currentFloor).GetLayer(FloorLayer.LayerType.MAZE)
	
	var exits = layer.GetSelfOwnedNeighboringExits(TwoDcellPos)
	
	#we itterate in reverse to remove them from Astar in the opposite direction they were added, helps with PointIDs not getting mixed
	for g in range(exits.size() - 1, -1, -1):
		var exit = exits[g]
		var triD = Helper.Vector2iTo3(exit, currentFloor)
		if (currentExits.has(triD)):
			currentExits.erase(triD)

	var collapeID = aStar.Astar.get_closest_point(collapse)
	
	layer.erase_cell(TwoDcellPos)
	
	var used = layer.get_used_cells()

	for dir in NEIGHBOR_DIRECTIONS:
		
		var neightborPos = TwoDcellPos + dir
		
		if (neightborPos.x < 0 or neightborPos.x > mapSize.x -1 or neightborPos.y < 0 or neightborPos.y > mapSize.y - 1):
			continue
		
		if (used.has(TwoDcellPos)):
			if (layer.CantReach(TwoDcellPos, dir, true)):
				continue
				
		else: if (used.has(neightborPos)):
				if (layer.CantReach(neightborPos, -dir, true)):
					continue
					
		var exitPointID = aStar.Astar.get_closest_point(Helper.Vector2iTo3(neightborPos, currentFloor), true)

		aStar.Astar.connect_points(collapeID, exitPointID)

	
	currentExits.append(collapse)


	var cell = cellData[collapse]
	
	
	RefillTile(TwoDcellPos ,cell)
	
	for g in rooms:
		g.erase(TwoDcellPos)
		
#-------------------------------------------------------
##Returns an array of floats containing the weights of each possible tile, checks if position is on edge of map and makes sure tiles that can't be placed there are given 0 weight
##Can also check placement of existing tiles and set weight of 0 to tiles that don't match
func GetTileWeights(pos : Vector2i, checkPlacement : bool = false) -> PackedFloat32Array:
	var availableWeights : PackedFloat32Array
	var layer = GetFloor(currentFloor).GetLayer(FloorLayer.LayerType.MAZE)
	for tile : collapseTileData in tileData:
		
		#If we are on map edge check to make sure we have wall facing edge
		if (pos.x == 0):
			if (!HasWallInDirection(tile, Vector2(-1,0))):
				availableWeights.append(0)
				continue
		else: if (pos.x == mapSize.x - 1):
			if (!HasWallInDirection(tile, Vector2(1,0))):
				availableWeights.append(0)
				continue
				
		if (pos.y == 0):
			if (!HasWallInDirection(tile, Vector2(0, -1))):
				availableWeights.append(0)
				continue
		else: if (pos.y == mapSize.y - 1):
			if (!HasWallInDirection(tile, Vector2(0, 1))):
				availableWeights.append(0)
				continue
		
		if (checkPlacement and !CanPlaceTile(tile.tileIndex, tile.tileRotation, pos, layer)):
			availableWeights.append(0)
			continue
			
		availableWeights.append(atlasData[tile.tileIndex].probability)
			
	return availableWeights

#----------------------------------------------
##Propagates constrains of provided cell, keeps going until no more changes are possible
func PropagateContrains(pos : Vector2i, collapsed : Array[Vector2i]) -> void:
	var cell = cellData[Helper.Vector2iTo3(pos, currentFloor)]
	
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		var TriDneighborPos = Helper.Vector2iTo3(neighborPos, currentFloor)
		if (cellData.has(TriDneighborPos)):
			var neighborCell : collapseCellData = cellData[TriDneighborPos]
			
			if (neighborCell.collapsed):
				continue
			
			var allowedTiles : Array[collapseTileData]
				
			for neightborTile in neighborCell.possibleTiles:
				for tile : collapseTileData in cell.possibleTiles:
					if (TilesMatch(tile, neightborTile, neightborDir)):
						allowedTiles.append(neightborTile)
						break
			
			var changed = neighborCell.possibleTiles.size() != allowedTiles.size()
			
			#neighborCell.possibleTiles.clear()
			neighborCell.possibleTiles = allowedTiles
			
			if (allowedTiles.size() == 1):
				collapsed.append(neighborPos)
				CellCollapsed(neighborPos)
			
			if (changed):
				PropagateContrains(neighborPos, collapsed)

#-----------------------------------------------
##Update contrains of provided cell based on neighbors
func UpdateConstrains(cell : collapseCellData, pos : Vector2i) -> void:
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		var TriDneighborPos = Helper.Vector2iTo3(neighborPos, currentFloor)
		
		if (cellData.has(TriDneighborPos)):
			var neighborCell : collapseCellData = cellData[TriDneighborPos]
				
			var allowedTiles : Array[collapseTileData]
			
			for tile : collapseTileData in cell.possibleTiles:
				for neightborTile in neighborCell.possibleTiles:
					if (TilesMatch(tile, neightborTile, neightborDir)):
						allowedTiles.append(tile)
						break

			cell.possibleTiles = allowedTiles
		else:
			var allowedTiles : Array[collapseTileData]
			for tile : collapseTileData in cell.possibleTiles:
				if (!HasWallInDirection(tile, neightborDir)):
					continue
				allowedTiles.append(tile)
					
			cell.possibleTiles = allowedTiles

#------------------------------------------------------------------
##Checks is tile has wall in specified direction
func HasWallInDirection(data : collapseTileData, dir : Vector2) -> bool:
	if (data.tileIndex == -1):
		return true
		
	var dat : TileData = atlasData[data.tileIndex]
	
	var finalDir = dir.rotated(-data.tileRotation).round()
	
	return dat.get_custom_data("Walls").has(finalDir)

#------------------------------------------------------------------
##Check if tile can be placed, uses also already placed tiles
func CanPlaceTile(tileIndex : int, rot : float, loc : Vector2i, layer : MazeFloorLayer) -> bool:
	var dat : TileData = atlasData[tileIndex]
	var used = layer.get_used_cells()
	
	for dir : Vector2i in NEIGHBOR_DIRECTIONS:
		var oppositeDir = -dir
		
		var neighborPos = loc + dir
		
		if (!used.has(neighborPos)):
			continue
		
		var neighborTileIndex = layer.get_cell_atlas_coords(neighborPos).x
		var neightborDat : TileData = atlasData[neighborTileIndex] 
		
		var finalDir = Helper.rotate_vector2i(dir, rot)
		var neightborAlt = layer.get_cell_alternative_tile(neighborPos)
		var finalOppositeDir = Helper.rotate_vector2i(oppositeDir, -Helper.GetRotationFromAltTile(neightborAlt))
		
		if (dat.get_custom_data("Walls").has(finalDir)):
			if (neightborDat.get_custom_data("Walls").has(finalOppositeDir)):
				continue
			#if we didn't return it means we didn't find wall so they don't match
			return false
		
		#do same for door walls
		if (dat.get_custom_data("DoorWalls").has(finalDir)):
			if (neightborDat.get_custom_data("DoorWalls").has(finalOppositeDir)):
				continue
			return false
		
		#if no walls were found to match direction then it means we check the destination tile to make sure it has no walls either
		if (neightborDat.get_custom_data("Walls").has(finalOppositeDir)):
			return false
		
		if (neightborDat.get_custom_data("DoorWalls").has(finalOppositeDir)):
			return false
	
	return true
	
#-------------------------------------------------------------
##Used to declare the blocking direction of each of the MAZE tiles
func TilesMatch (originData : collapseTileData, destinationData : collapseTileData, dir : Vector2) -> bool:
	var oppositeDir = -dir

	var dat : TileData = atlasData[originData.tileIndex]
	var dat2 : TileData = atlasData[destinationData.tileIndex]
	
	var finalDir = dir.rotated(-originData.tileRotation).round()
	var finalOppositeDir = oppositeDir.rotated(-destinationData.tileRotation).round()
	
	if (dat.get_custom_data("Walls").has(finalDir)):
		if (dat2.get_custom_data("Walls").has(finalOppositeDir)):
			return true
		#if we didn't return it means we didn't find wall so they don't match
		return false
	
	#do same for door walls
	if (dat.get_custom_data("DoorWalls").has(finalDir)):
		if (dat2.get_custom_data("DoorWalls").has(finalOppositeDir)):
			return true
		return false
	
	#if no walls were found to match direction then it means we check the destination tile to make sure it has no walls either
	if (dat2.get_custom_data("Walls").has(finalOppositeDir)):
		return false
	
	if (dat2.get_custom_data("DoorWalls").has(finalOppositeDir)):
		return false
	
	return true
