@tool
extends Map

class_name RandomisedMap

@export var mapSize : Vector2i = Vector2i(40, 40)
@export var usePatterns : bool = true
@export var active : bool = true
@export var solveStrays : bool = true
@export var collapseSeed : int = -1
@export_range(0, 1.0, 0.05) var GenerationCooldown : float = 0.2
@export_tool_button("Generate Map") var RegenerateAction = CollapseMap
@export_tool_button("Clear Map") var clear = CleanMap


const NEIGHBOR_DIRECTIONS : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const rotations : Array[float] = [0, PI/2, PI, -PI/2]

var originalTiles : Array[Vector2i]
var cellData : Dictionary[Vector2i, collapseCellData]
var tileData : Array[collapseTileData]
var atlasData : Dictionary[int, Dictionary]

var r : RandomNumberGenerator

var i : float = 0.2

func _process(delta: float) -> void:
	if (!active):
		return
		
	i -= delta
	
	if (i > 0):
		return
	
	i = GenerationCooldown
	
	
	var possible : Array[Vector2i]
	
	if (cellData.size() > 0):

		var currentEntropy = 99999999
		for g in cellData:
			var cell = cellData[g]
			if (cell.collapsed):
				continue
			var cellEntropy = cell.GetEntropy(atlasData)
			#print(cellEntropy)
			if cellEntropy < currentEntropy:
				possible.clear()
				currentEntropy = cellEntropy
				#nextToCollapse = g
				possible.append(g)
			else: if cellEntropy == currentEntropy:
				possible.append(g)

	
	if (possible.size() > 0):
		var randomIndex = r.randi_range(0, possible.size() - 1)
		var cellPos = possible[randomIndex]

		CellCollapsed(cellPos)
		
		#if (solveStrays):
			#var fl = GetFloor(0)
			#var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
			#var rooms = layer.separate_into_islands()
			#
			#if (rooms.size() > 1):
				#var cell = cellData[cellPos]
				#cell.collapsed = false
				#RefillTile(cellPos, cell)
				#return
		
		PropagateContrains(cellPos)
		queue_redraw()
		
	else: if (solveStrays):
		var fl = GetFloor(0)
		var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
		var rooms = layer.separate_into_islands()
		if (rooms.size() > 1):
			atlasData[-1]["CollapseWeight"] = 1
			
			var smallerRoom : Array
			var smallerRoomSize = 99999
			for room in rooms:
				if (room.size() < smallerRoomSize):
					smallerRoomSize = room.size()
					smallerRoom = room

			for tile in smallerRoom:
				if (!originalTiles.has(tile)):
					var cell : collapseCellData = cellData[tile]
					RefillTile(tile, cell)
					#UpdateConstrains(cell, tile)
				for neightborDir in NEIGHBOR_DIRECTIONS:
					var neighborPos = tile + neightborDir
					if (originalTiles.has(neighborPos) or smallerRoom.has(neighborPos)):
						continue
					if (cellData.has(neighborPos)):
						var neighborCell : collapseCellData = cellData[neighborPos]
						RefillTile(neighborPos, neighborCell)
						#UpdateConstrains(neighborCell, neighborPos)
				
			for tile in smallerRoom:
				if (!originalTiles.has(tile)):
					var cell : collapseCellData = cellData[tile]
					UpdateConstrains(cell, tile)
				for neightborDir in NEIGHBOR_DIRECTIONS:
					var neighborPos = tile + neightborDir
					if (originalTiles.has(neighborPos) or smallerRoom.has(neighborPos)):
						continue
					if (cellData.has(neighborPos)):
						var neighborCell : collapseCellData = cellData[neighborPos]
						UpdateConstrains(neighborCell, neighborPos)
		
		queue_redraw()

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
		
		
func _draw() -> void:
	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	for g in cellData:
		var cell = cellData[g]
		if (cell.collapsed):
			continue

		var text = var_to_str(cellData[g].possibleTiles.size())
		
		var stringSize = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2) / 4.0
		stringSize.y *= -1
		
		draw_string(ThemeDB.fallback_font, layer.map_to_local(g) - stringSize, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2)

func CleanMap() -> void:
	for fl in Floors:
		for layer : TileMapLayer in fl.get_children():
			layer.clear()

func CollapseMap() -> void:
	
	#weights.clear()
	
	r = RandomNumberGenerator.new()
	if (collapseSeed != -1):
		r.seed = collapseSeed
		
	var fl = GetFloor(0)
	var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	
	if (usePatterns):
		var paterns : Array[TileMapPattern]
		
		for pat in layer.tile_set.get_patterns_count():
			paterns.append(layer.tile_set.get_pattern(pat))
		
		#check for spots to fit any of the patterns
		while (paterns.size() > 0):
			var index = r.randi_range(0, paterns.size() - 1)
			var randomPatern : TileMapPattern = paterns[index]
			paterns.remove_at(index)
			var randomPosition = Vector2i(r.randi_range(1, mapSize.x - 2 - randomPatern.get_size().x), r.randi_range(1, mapSize.y - 2 - randomPatern.get_size().y))
			
			if (can_place_pattern(layer, randomPatern, randomPosition)):
				layer.set_pattern(randomPosition, randomPatern)
		
		layer.update_internals()

	UpdateAtlasData(layer)
	
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
		#positionCellData.collapsed = true
		
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
	
	queue_redraw()

#-----------------------------------------------
func UpdateAtlasData(layer : MazeFloorLayer) -> void:
	atlasData.clear()
	
	var emptyData : Dictionary = {
		"Walls" : NEIGHBOR_DIRECTIONS,
		"DoorWalls" : [],
		"CollapseWeight" : 10
	}

	atlasData[-1] = emptyData
	
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
		
	var fl = GetFloor(0)
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
