@tool
extends Map

class_name RandomisedMap

@export var mapSize : Vector2i = Vector2i(40, 40)
@export_tool_button("Generate Map") var RegenerateAction = CollapseMap

var cellData : Dictionary[Vector2i, collapseCellData]
var nextToCollapse : Vector2i = Vector2i(99999,99999)

var i : float = 0.2

func _process(delta: float) -> void:
	i -= delta
	
	if (i > 0):
		return
	
	i = 0.2
	
	if (nextToCollapse != Vector2i(99999,99999)):
		var fl = GetFloor(0)
		var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
		var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)
		collapseCell(nextToCollapse, tileAtlas)

func CleanMap() -> void:
	for fl in Floors:
		for layer : TileMapLayer in fl.get_children():
			layer.clear()

func CollapseMap() -> void:
	CleanMap()
	
	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)

	#var tileAtlas : TileSetAtlasSource = layer.tile_set.get_source(10)

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
					
					positionCellData.possibleTiles.append(tileData)
					
			cellData[pos] = positionCellData
	
	var randomFirstCellPosition = cellData.keys().pick_random()
	
	nextToCollapse = randomFirstCellPosition
	#while (nextToCollapse != Vector2i(99999,99999)):
		#nextToCollapse = collapseCell(nextToCollapse, cellData, layer)
	
	
func collapseCell(cellPos : Vector2i, atlas : TileSetAtlasSource) -> void:
	var cell = cellData[cellPos]
	cellData.erase(cellPos)
	var pickedTile = cell.possibleTiles.pick_random()
	
	cell.possibleTiles.clear()
	cell.possibleTiles.append(pickedTile)
	cell.collapsed = true
	
	var lowestEntropyNeighbor : Vector2i = Vector2i(99999,99999)
	var lowestEntropy : int = 99999
	
	var neighborDirections : Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for neightborDir in neighborDirections:
		var neighborPos = cellPos + neightborDir
		if (cellData.has(neighborPos)):
			var neighborCell : collapseCellData = cellData[neighborPos]
			
			if (neighborCell.GetEntropy() == 1 or neighborCell.collapsed):
				continue
			
			var allowedTiles : Array[collapseTileData]
				
			for neightborTile in neighborCell.possibleTiles:
				if (TilesMatch(pickedTile, neightborTile, neightborDir, atlas)):
					allowedTiles.append(neightborTile)
			
			neighborCell.possibleTiles.clear()
			neighborCell.possibleTiles = allowedTiles
			
			if (lowestEntropy > neighborCell.GetEntropy() and neighborCell.GetEntropy() > 0):
				lowestEntropy = neighborCell.GetEntropy()
				lowestEntropyNeighbor = neighborPos
	
	nextToCollapse = lowestEntropyNeighbor
	var fl = GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	layer.set_cell(cellPos, 10, Vector2i(pickedTile.tileIndex, 0), GetTileAltFromRotation(pickedTile.tileRotation))

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
