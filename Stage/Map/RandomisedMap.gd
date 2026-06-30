@tool
extends Map

class_name RandomisedMap

@export var mapSize : Vector2i = Vector2i(40, 40)
@export var usePatterns : bool = true
@export var active : bool = true
@export var collapseSeed : int = -1
@export var collapseAll : bool = false
@export var allowedPatterns : PackedInt32Array
@export var drawAStar : bool = false
@export var floorsToGenerate : PackedInt32Array = []

@export_tool_button("Generate Map") var RegenerateAction = CollapseMap
@export_tool_button("Clear Map") var clear = CleanMap

const NEIGHBOR_DIRECTIONS : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const rotations : Array[float] = [0, PI/2, PI, -PI/2]

var currentExits : Array[Vector2i]
var originalTiles : Array[Vector2i]
var cellData : Dictionary[Vector2i, collapseCellData]
var tileData : Array[collapseTileData]
var atlasData : Dictionary[int, Dictionary]

var generatedFloors : PackedInt32Array = []
var currentFloor : int = 0

var rooms : Array
var aStar : AStar2D

var r : RandomNumberGenerator

var finised : bool = false


func generate_maze(spawnMons : bool) -> void:
	
	if (finised):
		super(spawnMons)
	else:
		if (Engine.is_editor_hint()):
			return
		CollapseMap()

func _process(_delta: float) -> void:
	if (!active or finised):
		return
	if (Engine.is_editor_hint()):
		collapseNext()
	
func collapseNext() -> void:

	var possible : Array[Vector2i] = GetPossibleCollapses()
	if (possible.size() == 0):
		#generatedFloors.append(currentFloor)
		#if (generatedFloors.size() != floorsToGenerate.size()):
			#currentFloor += 1
			#return
		var f = GetFloor(currentFloor)
		var mapInfoLayer = f.GetLayer(FloorLayer.LayerType.MAP_INFO)
		var mazeLayer = f.GetLayer(FloorLayer.LayerType.MAZE)
		var monsterLayer = f.GetLayer(FloorLayer.LayerType.MONSTERS)
		var used = mazeLayer.get_used_cells()
		var spawnIndex = r.randi_range(0, used.size() - 1)
		mapInfoLayer.set_cell(used[spawnIndex], 0, Vector2i(14,0))
		
		for g in (mapSize.x * mapSize.y) / 100:
			var monIndex = r.randi_range(0, used.size() - 1)
			monsterLayer.set_cell(used[monIndex], 0, Vector2i(0,0))
		
		finised = true
		generate_maze(true)
		return
		
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	#var usecbefore = Time.get_ticks_usec()
	var msbefore = Time.get_ticks_msec()
	#while (Time.get_ticks_msec() - msbefore < 12):
	for i in 5:
		if (possible.size() == 0):
			possible = GetPossibleCollapses()
			if (possible.size() == 0):
				break
		#var msBeforCell = Time.get_ticks_msec()
		
		var randomIndex = r.randi_range(0, possible.size() - 1)
		var cellPos = possible[randomIndex]

		CellCollapsed(cellPos)
		
		currentExits.erase(cellPos)

		var newExits = layer.GetNeighboringExits(cellPos)
		
		var ownerRooms : Array
		
		#find the owner room of this cell
		for g : Array in rooms:
			for neighbor in NEIGHBOR_DIRECTIONS:
				if (g.has(cellPos + neighbor) and !layer.CantReach(cellPos, neighbor, true)):
					ownerRooms.append(g)
					break
		
		var originalRooms = rooms.duplicate()

		#if multiple owners exist we need to merge them since the cell bridges them.
		if (ownerRooms.size() > 1):
			var combined : Array
			for g in ownerRooms:
				combined.append_array(g)
				rooms.erase(g)
			rooms.append(combined)
			combined.append(cellPos)
			print("Combined rooms")
		else: if (ownerRooms.size() > 0):
			ownerRooms[0].append(cellPos)
		else:
			continue
		
		#if multiple rooms exist we need to check if they have exits, if not we take back this collapse
		var cancel : bool = false
		
		for room in rooms:
			if (RoomHasExit(room, newExits)):
				continue
			var cell = cellData[cellPos]
			RefillTile(cellPos, cell)
			UpdateConstrains(cell, cellPos)
			layer.erase_cell(cellPos)
			print("Cell aborted")
			#layer.update_internals()
			if (Engine.is_editor_hint()):
				queue_redraw()
			cancel = true
			rooms = originalRooms
			for g in rooms:
				g.erase(cellPos)
			currentExits.append(cellPos)
			break
					
		if (!cancel):
			possible.remove_at(randomIndex)
			var collapsedCellID = aStar.get_closest_point(cellPos)
		
			for g in newExits:
				if (currentExits.has(g)):
					var exitPointID = aStar.get_closest_point(g)
					aStar.connect_points(collapsedCellID, exitPointID)
				else:
					var exitPointID = aStar.get_point_count()
					aStar.add_point(exitPointID ,g)
					aStar.connect_points(collapsedCellID, exitPointID)
					
					currentExits.append(g)
				
			PropagateContrains(cellPos)
			#print("Cell took {0}ms".format([Time.get_ticks_msec() - msBeforCell]))
			
	#var usecAfter = Time.get_ticks_usec()
	#print(usecAfter - usecbefore)
	#layer.update_internals()
	if (Engine.is_editor_hint()):
		queue_redraw()

func GetPossibleCollapses() -> Array[Vector2i]:
	var possible : Array[Vector2i]
	var currentEntropy = INF
	for g in cellData:
		if (collapseAll):
			if (currentExits.size() > 0 and !currentExits.has(g)):
				continue
		else: if (!currentExits.has(g)):
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

func RoomHasExit(room : Array, newExits : Array[Vector2i]) -> bool:
	for g in currentExits:
		for neighbor in NEIGHBOR_DIRECTIONS:
			if (room.has(g + neighbor)):
				return true
				
	for g in newExits:
		for neighbor in NEIGHBOR_DIRECTIONS:
			if (room.has(g + neighbor)):
				return true
				
	return false
#------------------------------------------------
func RefillTile(tilePos : Vector2i, cell : collapseCellData) -> void:
	cell.possibleTiles.clear()
	cell.collapsed = false
	for tile in tileData:
		if (tilePos.x == 0):
			if (!TestDirection(tile, Vector2(-1,0))):
				continue
		else: if (tilePos.x == mapSize.x - 1):
			if (!TestDirection(tile, Vector2(1,0))):
				continue
				
		if (tilePos.y == 0):
			if (!TestDirection(tile, Vector2(0, -1))):
				continue
		else: if (tilePos.y == mapSize.y - 1):
			if (!TestDirection(tile, Vector2(0, 1))):
				continue
		
		cell.possibleTiles.append(tile)
		
#----------------------------------------------------
#debug
func _draw() -> void:
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	for g in cellData:
		var cell = cellData[g]
		if (cell.collapsed):
			continue

		var text = var_to_str(cellData[g].possibleTiles.size())
		
		var stringSize = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2) / 4.0
		stringSize.y *= -1
		
		draw_string(ThemeDB.fallback_font, layer.map_to_local(g) - stringSize, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)
	
	if (drawAStar):
		var used = layer.get_used_cells()
		
		for g in used:
			var pointId = aStar.get_closest_point(g)
			var connections = aStar.get_point_connections(pointId)
			for connection in connections:
				draw_line(layer.map_to_local(g), layer.map_to_local(aStar.get_point_position(connection)), Color(1,0,0, 0.3))
		

#---------------------------------------------------
func CleanMap() -> void:
	for fl in Floors:
		for layer : TileMapLayer in fl.get_children():
			layer.clear()

#----------------------------------------------------
#Starts the generation of the map
func CollapseMap() -> void:
	finised = false
	r = RandomNumberGenerator.new()
	if (collapseSeed != -1):
		r.seed = collapseSeed
	
	generatedFloors.clear()
	currentFloor = floorsToGenerate[0]
	
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	if (usePatterns):

		var paterns : Array[TileMapPattern]
		
		for pat in layer.tile_set.get_patterns_count():
			if (allowedPatterns.has(pat)):
				paterns.append(layer.tile_set.get_pattern(pat))
		
		#check for spots to fit any of the patterns
		while (paterns.size() > 0):
			var index = r.randi_range(0, paterns.size() - 1)
			var randomPatern : TileMapPattern = rotate_pattern(paterns[index], r.randi_range(0, 3))
			paterns.remove_at(index)
			var randomPosition = Vector2i(r.randi_range(1, mapSize.x - 2 - randomPatern.get_size().x), r.randi_range(1, mapSize.y - 2 - randomPatern.get_size().y))

			var maxTries : int = 5
			var foudPlace = can_place_pattern(layer, randomPatern, randomPosition)
			while (!foudPlace and maxTries > 0):
				randomPosition = Vector2i(r.randi_range(1, mapSize.x - 2 - randomPatern.get_size().x), r.randi_range(1, mapSize.y - 2 - randomPatern.get_size().y))
				foudPlace = can_place_pattern(layer, randomPatern, randomPosition)
				maxTries -= 1
				
			if (foudPlace):
				layer.set_pattern(randomPosition, randomPatern)
		
	#layer.update_internals()
	
	UpdateAtlasData()
	
	cellData = {}
	
	
	var Usedcells = layer.get_used_cells()
	originalTiles.clear()
	for cell in Usedcells:
		var positionCellData = collapseCellData.new()
		
		originalTiles.append(cell)
		
		var dat = collapseTileData.new()
		dat.tileIndex = layer.get_cell_atlas_coords(cell).x
		dat.tileRotation = layer.GetTileRotationRadians(cell)
		
		positionCellData.possibleTiles.append(dat)
		positionCellData.collapsed = true
		
		cellData[cell] = positionCellData

	for x in mapSize.x:
		for y in mapSize.y:
			var pos = Vector2i(x, y)
			
			if (cellData.has(pos)):
				continue
			
			var positionCellData = collapseCellData.new()
			
			RefillTile(pos, positionCellData)
					
			cellData[pos] = positionCellData
	
	for cell in Usedcells:
		PropagateContrains(cell)
	
	aStar = layer.GetAStar()
	currentExits = layer.find_exits()
	rooms = layer.separate_into_islands()
	
	
	
	
	if (Engine.is_editor_hint()):
		queue_redraw()
	else:
		while(!finised):
			collapseNext()

func rotate_pattern(pattern: TileMapPattern, turns: int) -> TileMapPattern:
	turns = posmod(turns, 4)

	var result := TileMapPattern.new()
	var cells := pattern.get_used_cells()

	# bounds
	var min_pos := cells[0]
	var max_pos := cells[0]

	for c in cells:
		min_pos = min_pos.min(c)
		max_pos = max_pos.max(c)

	var w = max_pos.x - min_pos.x + 1
	var h = max_pos.y - min_pos.y + 1
	
	var fl = GetFloor(currentFloor)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	for cell in cells:
		var local = cell - min_pos
		var new_pos: Vector2i

		# rotate position
		match turns:
			0:
				new_pos = local
			1:
				new_pos = Vector2i(h - 1 - local.y, local.x)
			2:
				new_pos = Vector2i(w - 1 - local.x, h - 1 - local.y)
			3:
				new_pos = Vector2i(local.y, w - 1 - local.x)

		# copy tile data
		var source_id = pattern.get_cell_source_id(cell)
		var atlas = pattern.get_cell_atlas_coords(cell)
		var altTile = pattern.get_cell_alternative_tile(cell)
		
		
		# get current rotation
		var rot_radians = layer.GetRotationFromAltTile(altTile)

		# apply room rotation
		rot_radians += turns * (PI * 0.5)
		
		rot_radians = wrapf(rot_radians, -PI/2, PI + PI/2)
		# convert rotation -> alternative tile (YOU provide this)
		var alternative = GetTileAltFromRotation(rot_radians)

		result.set_cell(
			new_pos,
			source_id,
			atlas,
			alternative
		)

	return result

#-----------------------------------------------
func UpdateAtlasData() -> void:
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
		var dataDict = TileDataToDict(dat)
		atlasData[tileIndex] = dataDict
	
	tileData.clear()
	for tileIndex : int in atlasData:
		for rot in rotations:
			var dat = collapseTileData.new()
			dat.tileIndex = tileIndex
			dat.tileRotation = rot
			
			tileData.append(dat)

#-----------------------------------------------
func TileDataToDict(dat : TileData) -> Dictionary:
	var dataDict : Dictionary = {
			"Walls" : dat.get_custom_data("Walls"),
			"DoorWalls" : dat.get_custom_data("DoorWalls"),
			"CollapseWeight" : dat.get_custom_data("CollapseWeight")
		}
	return dataDict

#-----------------------------------------------
##Checks if pattern can be placed in position provided
func can_place_pattern(tilemap: TileMapLayer,pattern: TileMapPattern, patternPosition: Vector2i) -> bool:
	
	for pattern_cell in pattern.get_used_cells():
		var map_cell = patternPosition + pattern_cell

		# Check map bounds
		if map_cell.x < 0 \
		or map_cell.y < 0 \
		or map_cell.x >= mapSize.x \
		or map_cell.y >= mapSize.y:
			return false

		# Check if something is already placed
		if tilemap.get_cell_source_id(map_cell) != -1:
			return false
		for neighbor in NEIGHBOR_DIRECTIONS:
			if tilemap.get_cell_source_id(map_cell + neighbor) != -1:
				return false

	return true

#-----------------------------------------------
func CellCollapsed(cellPos : Vector2i) -> void:
	var cell = cellData[cellPos]
	var availableWeights : PackedFloat32Array
	
	for tile : collapseTileData in cell.possibleTiles :
		availableWeights.append(atlasData[tile.tileIndex]["CollapseWeight"])

	var picked = r.rand_weighted(availableWeights)
	
	var pickedTile : collapseTileData = cell.possibleTiles[picked]
	
	cell.possibleTiles.clear()
	cell.possibleTiles.append(pickedTile)
	cell.collapsed = true

	if(pickedTile.tileIndex == -1):
		return
		
	var fl = GetFloor(currentFloor)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	layer.set_cell(cellPos, 10, Vector2i(pickedTile.tileIndex, 0), GetTileAltFromRotation(pickedTile.tileRotation))


#----------------------------------------------
##Propagates constrains of provided cell, keeps going until no more changes are possible
func PropagateContrains(pos : Vector2i) -> void:
	var cell = cellData[pos]
	
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
			
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
				CellCollapsed(neighborPos)
			
			if (changed):
				PropagateContrains(neighborPos)

func UpdateConstrains(cell : collapseCellData, pos : Vector2i) -> void:
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
				
			var allowedTiles : Array[collapseTileData]
			
			for tile : collapseTileData in cell.possibleTiles:
				for neightborTile in neighborCell.possibleTiles:
					if (TilesMatch(tile, neightborTile, neightborDir)):
						allowedTiles.append(tile)
						break

			cell.possibleTiles = allowedTiles
	

func GetTileAltFromRotation(rot : float) -> int:
	var tile_alternate : int = 0
	match rot:
		PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		PI:
			tile_alternate = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		-PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
			
	return tile_alternate

func TestDirection(data : collapseTileData, dir : Vector2) -> bool:
	if (data.tileIndex == -1):
		return true
		
	var dat : Dictionary = atlasData[data.tileIndex]
		
	for wall : Vector2 in dat["Walls"]:
		var wallDir = wall.rotated(data.tileRotation).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			return true
			
	return false

##Used to declare the blocking direction of each of the MAZE tiles
func TilesMatch (originData : collapseTileData, destinationData : collapseTileData, dir : Vector2) -> bool:
	var oppositeDir = -dir

	var dat : Dictionary = atlasData[originData.tileIndex]
	var dat2 : Dictionary = atlasData[destinationData.tileIndex]

	for wall : Vector2 in dat["Walls"]:
		var wallDir = wall.rotated(originData.tileRotation).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2["Walls"]:
				var oppositeWallDir = oppositewall.rotated(destinationData.tileRotation).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false

	#do same for door walls
	for wall : Vector2 in dat["DoorWalls"]:
		var wallDir = wall.rotated(originData.tileRotation).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2["DoorWalls"]:
				var oppositeWallDir = oppositewall.rotated(destinationData.tileRotation).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false

	#if no walls were found to match direction then it means we check the destination tile to make sure it has no walls either
	for oppositewall : Vector2 in dat2["Walls"]:
		var oppositeWallDir = oppositewall.rotated(destinationData.tileRotation).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false
			
	for oppositewall : Vector2 in dat2["DoorWalls"]:
		var oppositeWallDir = oppositewall.rotated(destinationData.tileRotation).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false

	
	return true
