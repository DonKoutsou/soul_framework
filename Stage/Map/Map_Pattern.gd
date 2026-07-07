@tool
extends Map

class_name Map_Pattern

@export var MaxPlacements : int = 1000

#int is flor and dict contains the patterns
var patterns : Dictionary[int, Dictionary]

var maxSpot : Vector2i = Vector2i.ZERO

func _ready() -> void:
	super()
	
	for floorIndex : int in GetFloorIndexes():
		var mazePattern = _contruct_pattern(FloorLayer.LayerType.MAZE, floorIndex)
		var monsterPattern = _contruct_pattern(FloorLayer.LayerType.MONSTERS, floorIndex)
		var mapInfoPattern = _contruct_pattern(FloorLayer.LayerType.MAP_INFO, floorIndex)
		var mapInfo2Pattern = _contruct_pattern(FloorLayer.LayerType.MAP_INFO2, floorIndex)
		var itemPattern = _contruct_pattern(FloorLayer.LayerType.ITEMS, floorIndex)
		
		if (mazePattern.get_size().x > maxSpot.x):
			maxSpot.x = mazePattern.get_size().x
		if (mazePattern.get_size().y > maxSpot.y):
			maxSpot.y = mazePattern.get_size().y
		
		patterns[floorIndex] = {
			FloorLayer.LayerType.MAZE : mazePattern, 
			FloorLayer.LayerType.MONSTERS : monsterPattern, 
			FloorLayer.LayerType.MAP_INFO : mapInfoPattern,
			FloorLayer.LayerType.MAP_INFO2 : mapInfo2Pattern,
			FloorLayer.LayerType.ITEMS : itemPattern}

func GetSize() -> Vector2i:
	return maxSpot

func GetFloorAmm() -> int:
	return Floors.size()

func GetFloorIndexes() -> Array[int]:
	var floorIndexes : Array[int] = []
	for g : FloorLayer in Floors:
		floorIndexes.append(g.FloorNumber)
	return floorIndexes

func GetFloorExtents() -> Vector2i:
	var minFloor = INF
	var maxFloor = -INF
	for g : FloorLayer in Floors:
		if (g.FloorNumber < minFloor):
			minFloor = g.FloorNumber
		if (g.FloorNumber > maxFloor):
			maxFloor = g.FloorNumber
	return Vector2i(minFloor, maxFloor)

func GetPattern(layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE, floorIndex : int = 0) -> TileMapPattern:
	return patterns[floorIndex][layer]

func _contruct_pattern(layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE, floorIndex : int = 0) -> TileMapPattern:
	var pattern = TileMapPattern.new()
	
	var fl = GetFloor(floorIndex)
	var mazeLayer = fl.GetLayer(layer)
	var used = mazeLayer.get_used_cells()
	
	for cell in used:
		pattern.set_cell(cell, mazeLayer.get_cell_source_id(cell), mazeLayer.get_cell_atlas_coords(cell), mazeLayer.get_cell_alternative_tile(cell))
	
	return pattern


func GetProps() -> Dictionary[Mesh, Array]:
	return Props

func GetMegaProps() -> Dictionary[Mesh, Array]:
	return MegaProps
