@tool
extends Map

class_name Map_Pattern

func GetPattern() -> TileMapPattern:
	var pattern = TileMapPattern.new()
	
	var fl = GetFloor(0)
	var mazeLayer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	var used = mazeLayer.get_used_cells()
	
	for cell in used:
		pattern.set_cell(cell, mazeLayer.get_cell_source_id(cell), mazeLayer.get_cell_atlas_coords(cell), mazeLayer.get_cell_alternative_tile(cell))
	
	return pattern

func GetProps() -> Dictionary[Mesh, Array]:
	return Props

func GetMegaProps() -> Dictionary[Mesh, Array]:
	return MegaProps
