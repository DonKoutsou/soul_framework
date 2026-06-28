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
const rotations : Array[int] = [0, 90, 180, -90]

var cellData : Dictionary[Vector2i, collapseCellData]
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
		var currentEntropy = 9999
		for g in cellData:
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
				
	if (possible.size() > 0):
		var randomIndex = r.randi_range(0, possible.size() - 1)
		collapseCell(possible[randomIndex])
	
		queue_redraw()
	else: if (solveStrays):
		var fl = GetFloor(0)
		var layer : MazeFloorLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
		var rooms = layer.separate_into_islands()
		if (rooms.size() > 1):
			var smallerRoom : Array
			var smallerRoomSize = 99999
			for room in rooms:
				if (room.size() < smallerRoomSize):
					smallerRoomSize = room.size()
					smallerRoom = room

			for tile in smallerRoom:
				var cell : collapseCellData = cellData[tile]
				cell.collapsed = false
				cell.possibleTiles.clear()
				RefillTile(tile, cell)
				
				for neightborDir in NEIGHBOR_DIRECTIONS:
					var neighborPos = tile + neightborDir
					if (cellData.has(neighborPos) and !smallerRoom.has(neighborPos)):
						var neighborCell : collapseCellData = cellData[neighborPos]
						neighborCell.collapsed = false
						neighborCell.possibleTiles.clear()
						RefillTile(neighborPos, neighborCell)
						
				
				
			for tile in smallerRoom:
				var cell : collapseCellData = cellData[tile]
				UpdateConstrains(cell, tile)
				for neightborDir in NEIGHBOR_DIRECTIONS:
					var neighborPos = tile + neightborDir
					if (cellData.has(neighborPos) and !smallerRoom.has(neighborPos)):
						var neighborCell : collapseCellData = cellData[neighborPos]
						UpdateConstrains(neighborCell, neighborPos)

func RefillTile(tilePos : Vector2i, cell : collapseCellData) -> void:
	for tileIndex : int in atlasData:
		for rot in rotations:
			
			var tileData = collapseTileData.new()
			tileData.tileIndex = tileIndex
			tileData.tileRotation = rot

			if (tilePos.x == 0):
				if (!TestDirection(tileData, Vector2(-1,0))):
					continue
			if (tilePos.x == mapSize.x - 1):
				if (!TestDirection(tileData, Vector2(1,0))):
					continue
			if (tilePos.y == 0):
				if (!TestDirection(tileData, Vector2(0, -1))):
					continue
			if (tilePos.y == mapSize.y - 1):
				if (!TestDirection(tileData, Vector2(0, 1))):
					continue
			
			cell.possibleTiles.append(tileData)
		
		
func _draw() -> void:
	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	for g in cellData:
		draw_string(ThemeDB.fallback_font, layer.map_to_local(g), var_to_str(cellData[g].possibleTiles.size()), HORIZONTAL_ALIGNMENT_CENTER, -1, 2)

func CleanMap() -> void:
	for fl in Floors:
		for layer : TileMapLayer in fl.get_children():
			layer.clear()

func CollapseMap() -> void:
	atlasData.clear()
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
			var randomPosition = Vector2i(r.randi_range(0, mapSize.x - 1), r.randi_range(0, mapSize.y - 1))
			
			if (can_place_pattern(layer, randomPatern, randomPosition)):
				layer.set_pattern(randomPosition, randomPatern)
		
		layer.update_internals()
	
	var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)
	
	var emptyData : Dictionary = {
		"Walls" : NEIGHBOR_DIRECTIONS,
		"DoorWalls" : [],
		"CollapseWeight" : 10
	}

	atlasData[-1] = emptyData
	
	
	for tileIndex : int in layer.tile_set.get_source(10).get_tiles_count():
		var dat : TileData = tileAtlas.get_tile_data(Vector2i(tileIndex, 0), 0)
		var dataDict : Dictionary = {
			"Walls" : dat.get_custom_data("Walls"),
			"DoorWalls" : dat.get_custom_data("DoorWalls"),
			"CollapseWeight" : dat.get_custom_data("CollapseWeight")
		}
		atlasData[tileIndex] = dataDict
	
	cellData = {}
	
	var Usedcells = layer.get_used_cells()
	
	for cell in Usedcells:
		var positionCellData = collapseCellData.new()
		
		var tileData = collapseTileData.new()
		tileData.tileIndex = layer.get_cell_atlas_coords(cell).x
		tileData.tileRotation = rad_to_deg(layer.GetTileRotationRadians(cell))
		
		positionCellData.possibleTiles.append(tileData)
		
		cellData[cell] = positionCellData
	
	for x in mapSize.x:
		for y in mapSize.y:
			var pos = Vector2i(x, y)
			
			if (cellData.has(pos)):
				continue
			
			var positionCellData = collapseCellData.new()
			
			for tileIndex : int in atlasData:
				
				for rot in rotations:
					
					var tileData = collapseTileData.new()
					tileData.tileIndex = tileIndex
					tileData.tileRotation = rot
					
					
					if (x == 0):
						if (!TestDirection(tileData, Vector2(-1,0))):
							continue
					if (x == mapSize.x - 1):
						if (!TestDirection(tileData, Vector2(1,0))):
							continue
					if (y == 0):
						if (!TestDirection(tileData, Vector2(0, -1))):
							continue
					if (y == mapSize.y - 1):
						if (!TestDirection(tileData, Vector2(0, 1))):
							continue
					
					positionCellData.possibleTiles.append(tileData)
					
			cellData[pos] = positionCellData
	
	for cell in Usedcells:
		var dat = cellData[cell]
		PropagateContrains(dat, cell)

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

func collapseCell(cellPos : Vector2i) -> void:
	var cell = cellData[cellPos]
	
	if (!cell.collapsed):
		CellCollapsed(cellPos)

	PropagateContrains(cell, cellPos)


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

func PropagateContrains(cell : collapseCellData, pos : Vector2i) -> void:
	
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
			
			if (neighborCell.collapsed):
				continue
			
			var allowedTiles : Array[collapseTileData]
				
			for neightborTile in neighborCell.possibleTiles:
				for tile : collapseTileData in cell.possibleTiles:
					if (!allowedTiles.has(neightborTile) and TilesMatch(tile, neightborTile, neightborDir)):
						allowedTiles.append(neightborTile)
			
			var changed = neighborCell.possibleTiles.size() != allowedTiles.size()
			#neighborCell.possibleTiles.clear()
			neighborCell.possibleTiles = allowedTiles
			
			if (allowedTiles.size() == 1):
				CellCollapsed(neighborPos)
			
			if (changed):
				PropagateContrains(neighborCell, neighborPos)

func UpdateConstrains(cell : collapseCellData, pos : Vector2i) -> void:
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
				
			var allowedTiles : Array[collapseTileData]
				
			for neightborTile in neighborCell.possibleTiles:
				for tile : collapseTileData in cell.possibleTiles:
					if (!allowedTiles.has(tile) and TilesMatch(tile, neightborTile, neightborDir)):
						allowedTiles.append(tile)

			cell.possibleTiles = allowedTiles
	

func GetTileAltFromRotation(rot : int) -> int:
	var tile_alternate : int = 0
	
	match rot:
		90:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		180:
			tile_alternate = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		-90:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
			
	return tile_alternate

func TestDirection(data : collapseTileData, dir : Vector2) -> bool:
	if (data.tileIndex == -1):
		return true
		
	var dat : Dictionary = atlasData[data.tileIndex]
		
	for wall : Vector2 in dat["Walls"]:
		var wallDir = wall.rotated(deg_to_rad(data.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			return true
			
	return false

##Used to declare the blocking direction of each of the MAZE tiles
func TilesMatch (originData : collapseTileData, destinationData : collapseTileData, dir : Vector2) -> bool:
	var oppositeDir = -dir

	var dat : Dictionary = atlasData[originData.tileIndex]
	var dat2 : Dictionary = atlasData[destinationData.tileIndex]

	for wall : Vector2 in dat["Walls"]:
		var wallDir = wall.rotated(deg_to_rad(originData.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2["Walls"]:
				var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false

	#do same for door walls
	for wall : Vector2 in dat["DoorWalls"]:
		var wallDir = wall.rotated(deg_to_rad(originData.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2["DoorWalls"]:
				var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false

	#if no walls were found to match direction then it means we check the destination tile to make sure it has no walls either
	for oppositewall : Vector2 in dat2["Walls"]:
		var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false
			
	for oppositewall : Vector2 in dat2["DoorWalls"]:
		var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false

	
	return true
