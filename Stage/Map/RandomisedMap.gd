@tool
extends Map

class_name RandomisedMap

@export var mapSize : Vector2i = Vector2i(40, 40)
@export var constrainPropagation : int = 1
@export var active : bool = true
@export var collapseSeed : int = -1
@export_range(0, 1.0, 0.05) var GenerationCooldown : float = 0.2
@export_tool_button("Generate Map") var RegenerateAction = CollapseMap
@export_tool_button("Clear Map") var clear = CleanMap

const NEIGHBOR_DIRECTIONS : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
var cellData : Dictionary[Vector2i, collapseCellData]

var r : RandomNumberGenerator
var weights : PackedFloat32Array
#var nextToCollapse : Vector2i = Vector2i(99999,99999)

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
			if cell.GetEntropy() < currentEntropy and !cell.collapsed:
				possible.clear()
				currentEntropy = cell.GetEntropy()
				#nextToCollapse = g
				possible.append(g)
			else: if cell.GetEntropy() == currentEntropy and !cell.collapsed:
				possible.append(g)
				
	if (possible.size() > 0):
		var fl = GetFloor(0)
		var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
		var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)
		var randomIndex = r.randi_range(0, possible.size() - 1)
		
		collapseCell(possible[randomIndex], tileAtlas)
	
	queue_redraw()
		
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
	CleanMap()
	weights.clear()
	r = RandomNumberGenerator.new()
	if (collapseSeed != -1):
		r.seed = collapseSeed
	
	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)

	var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)
	
	for tileIndex : int in layer.tile_set.get_source(10).get_tiles_count():
		var dat : TileData = tileAtlas.get_tile_data(Vector2i(tileIndex, 0), 0)
		var weight = dat.get_custom_data("CollapseWeight")
		weights.append(weight)
		
	cellData = {}
	
	var rotations : Array[int] = [0, 90, 180, -90]
	
	for x in mapSize.x:
		for y in mapSize.y:
			var pos = Vector2i(x, y)
			var positionCellData = collapseCellData.new()
			
			for tileIndex : int in layer.tile_set.get_source(10).get_tiles_count():
				
				for rot in rotations:
					
					var tileData = collapseTileData.new()
					tileData.tileIndex = tileIndex
					tileData.tileRotation = rot
					
					if (x == 0):
						if (!TestDirection(tileData, Vector2(-1,0), tileAtlas)):
							continue
					if (x == mapSize.x - 1):
						if (!TestDirection(tileData, Vector2(1,0), tileAtlas)):
							continue
					if (y == 0):
						if (!TestDirection(tileData, Vector2(0, -1), tileAtlas)):
							continue
					if (y == mapSize.y - 1):
						if (!TestDirection(tileData, Vector2(0, 1), tileAtlas)):
							continue
					
					positionCellData.possibleTiles.append(tileData)
					
			cellData[pos] = positionCellData
	
	#var randomFirstCellPosition = cellData.keys().pick_random()
	#collapseCell(randomFirstCellPosition, tileAtlas)
	#nextToCollapse = randomFirstCellPosition
	#while (nextToCollapse != Vector2i(99999,99999)):
		#nextToCollapse = collapseCell(nextToCollapse, cellData, layer)
	
func collapseCell(cellPos : Vector2i, atlas : TileSetAtlasSource) -> void:
	var cell = cellData[cellPos]
	
	if (!cell.collapsed):
		CellCollapsed(cellPos)

	PropagateContrains(cell, cellPos, atlas, constrainPropagation)


func CellCollapsed(cellPos : Vector2i) -> void:
	var cell = cellData[cellPos]
	
	var availableWeights : PackedFloat32Array
	
	for tile : collapseTileData in cell.possibleTiles :
		availableWeights.append(weights[tile.tileIndex])

	var picked = r.rand_weighted(availableWeights)
	
	var pickedTile = cell.possibleTiles[picked]
	
	cell.possibleTiles.clear()
	cell.possibleTiles.append(pickedTile)
	cell.collapsed = true

	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	layer.set_cell(cellPos, 10, Vector2i(pickedTile.tileIndex, 0), GetTileAltFromRotation(pickedTile.tileRotation))

func PropagateContrains(cell : collapseCellData, pos : Vector2i, atlas : TileSetAtlasSource, propagation : int) -> void:
	var prop = propagation - 1
	
	for neightborDir in NEIGHBOR_DIRECTIONS:
		var neighborPos = pos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
			
			if (neighborCell.collapsed):
				continue
			
			var allowedTiles : Array[collapseTileData]
				
			for neightborTile in neighborCell.possibleTiles:
				for tile : collapseTileData in cell.possibleTiles:
					if (!allowedTiles.has(neightborTile) and TilesMatch(tile, neightborTile, neightborDir, atlas)):
						allowedTiles.append(neightborTile)
			
			#neighborCell.possibleTiles.clear()
			neighborCell.possibleTiles = allowedTiles
			
			if (allowedTiles.size() == 1):
				CellCollapsed(neighborPos)

	if (prop > 0):
		for neightborDir in NEIGHBOR_DIRECTIONS:
			var neighborPos = pos + neightborDir
			if (cellData.has(neighborPos)):
				var neighborCell : collapseCellData = cellData[neighborPos]
				
				PropagateContrains(neighborCell, neighborPos, atlas, prop)

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

func TestDirection(data : collapseTileData, dir : Vector2, atlas : TileSetAtlasSource) -> bool:
	var dat : TileData = atlas.get_tile_data(Vector2i(data.tileIndex, 0), 0)
	for wall : Vector2 in dat.get_custom_data("Walls"):
		var wallDir = wall.rotated(deg_to_rad(data.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			return true
			
	return false

##Used to declare the blocking direction of each of the MAZE tiles
func TilesMatch (originData : collapseTileData, destinationData : collapseTileData, dir : Vector2, atlas : TileSetAtlasSource) -> bool:
	var dat : TileData = atlas.get_tile_data(Vector2i(originData.tileIndex, 0), 0)

	var dat2 : TileData = atlas.get_tile_data(Vector2i(destinationData.tileIndex, 0), 0)
	
	var oppositeDir = -dir
	for wall : Vector2 in dat.get_custom_data("Walls"):
		var wallDir = wall.rotated(deg_to_rad(originData.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2.get_custom_data("Walls"):
				var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false
	
	#do same for door walls
	for wall : Vector2 in dat.get_custom_data("DoorWalls"):
		var wallDir = wall.rotated(deg_to_rad(originData.tileRotation)).round()
		if (dir.is_equal_approx(wallDir)): ##we found wall the matches direction
			
			#check if other tile has wall in opposite Dir
			for oppositewall : Vector2 in dat2.get_custom_data("DoorWalls"):
				var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
				if (oppositeDir.is_equal_approx(oppositeWallDir)):
					return true
			
			#if we didn't return it means we didn't find wall so they don't match
			return false

	#if no walls were found to match direction then it means we check the destination tile to make sure it has no walls either
	for oppositewall : Vector2 in dat2.get_custom_data("Walls"):
		var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false
			
	for oppositewall : Vector2 in dat2.get_custom_data("DoorWalls"):
		var oppositeWallDir = oppositewall.rotated(deg_to_rad(destinationData.tileRotation)).round()
		if (oppositeDir.is_equal_approx(oppositeWallDir)):
			return false

	
	return true
