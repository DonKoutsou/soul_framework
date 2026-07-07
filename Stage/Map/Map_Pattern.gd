@tool
extends Map

class_name Map_Pattern

@export var MaxPlacements : int = 1000

func GetFloorAmm() -> void:
	Floors.size()

func GetFloorExtents() -> Vector2i:
	var minFloor = INF
	var maxFloor = -INF
	for g : FloorLayer in Floors:
		if (g.FloorNumber < minFloor):
			minFloor = g.FloorNumber
		if (g.FloorNumber > maxFloor):
			maxFloor = g.FloorNumber
	return Vector2i(minFloor, maxFloor)

func GetPattern(layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE) -> TileMapPattern:
	var pattern = TileMapPattern.new()
	
	var fl = GetFloor(0)
	var mazeLayer = fl.GetLayer(layer)
	var used = mazeLayer.get_used_cells()
	
	for cell in used:
		pattern.set_cell(cell, mazeLayer.get_cell_source_id(cell), mazeLayer.get_cell_atlas_coords(cell), mazeLayer.get_cell_alternative_tile(cell))
	
	return pattern


func GetProps() -> Dictionary[Mesh, Array]:
	return Props

func GetMegaProps() -> Dictionary[Mesh, Array]:
	return MegaProps
