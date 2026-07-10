@tool
extends Node2D

class_name FloorLayer

@export var HouseCatalogue : Dictionary[Vector2, PackedScene]
@export var UseFloorAsCeiling : bool = false
@export var SpawnCeiling : bool = true
@export var RandomiseCeilingRotation : bool = true
@export var RandomiseFloorRotation : bool = true
@export var AddDecorationOnWater : bool = true
@export var FloorNumber : int = 0:
	set(value):
		FloorNumber = value
		name = "Floor_" + var_to_str(FloorNumber)

var Layers : Dictionary[LayerType, BaseFloorLayer]

const layerProcessPriority : Array[LayerType] = [
		LayerType.ITEMS,
		LayerType.MAP_INFO,
		LayerType.MONSTERS,
		LayerType.LEVERS,
		LayerType.DOORS,
		LayerType.EXITS,
		LayerType.TEXTS,
		LayerType.PLATES,
		LayerType.MOVABLES,
		LayerType.MAP_INFO2,
		LayerType.PROJECTILE_SWITCH,
		LayerType.LOCKS,
		LayerType.CHARACTERS,
		LayerType.MAZE
		]

func _ready() -> void:
	_store_layers()

func _store_layers() -> void:
	for layer : BaseFloorLayer in get_children():
		Layers[layer.layerType] = layer

enum LayerType{
		MAZE,
		ITEMS,
		MAP_INFO,
		MONSTERS,
		LEVERS,
		DOORS,
		EXITS,
		TEXTS,
		PLATES,
		MOVABLES,
		MAP_INFO2,
		PROJECTILE_SWITCH,
		LOCKS,
		CHARACTERS
	}

func GetLayers() -> Array[BaseFloorLayer]:
	return Layers.values()

func GetLayer(Type : LayerType) -> BaseFloorLayer:
	return Layers[Type]

func ApplyPattern(pattern : Map_Pattern, patternFloorIndex : int, pos : Vector2i, rot : int) -> void:
	var layer = GetLayer(FloorLayer.LayerType.MAZE)
	var patternSize = pattern.GetSize()
	
	var originalPatern : TileMapPattern = pattern.GetPattern(FloorLayer.LayerType.MAZE, patternFloorIndex)
	var randomPatern : TileMapPattern = Helper.rotate_pattern(originalPatern, rot, patternSize)

	layer.set_pattern(pos, randomPatern)
	
	var mapInfoLayer = GetLayer(FloorLayer.LayerType.MAP_INFO)
	var mapInfoPattern : TileMapPattern = Helper.rotate_pattern(pattern.GetPattern(FloorLayer.LayerType.MAP_INFO, patternFloorIndex), rot, patternSize)
	mapInfoLayer.set_pattern(pos, mapInfoPattern)
	
	var mapInfoLayer2 = GetLayer(FloorLayer.LayerType.MAP_INFO2)
	var mapInfoPattern2 : TileMapPattern = Helper.rotate_pattern(pattern.GetPattern(FloorLayer.LayerType.MAP_INFO2, patternFloorIndex), rot, patternSize)
	mapInfoLayer2.set_pattern(pos, mapInfoPattern2)
	
	var monsterLayer = GetLayer(FloorLayer.LayerType.MONSTERS)
	var monsterPattern : TileMapPattern = Helper.rotate_pattern(pattern.GetPattern(FloorLayer.LayerType.MONSTERS, patternFloorIndex), rot, patternSize)
	monsterLayer.set_pattern(pos, monsterPattern)
	
	var itemLayer = GetLayer(FloorLayer.LayerType.ITEMS)
	var itemPattern : TileMapPattern = Helper.rotate_pattern(pattern.GetPattern(FloorLayer.LayerType.ITEMS, patternFloorIndex), rot, patternSize)
	itemLayer.set_pattern(pos, itemPattern)

#-----------------------------------------------
##Checks if pattern can be placed in position provided
func can_place_pattern(pattern: TileMapPattern, patternPosition: Vector2i, mapSize : Vector2i) -> bool:
	var layer = GetLayer(FloorLayer.LayerType.MAZE)
	
	var usedCells = layer.get_used_cells()
	for pattern_cell in pattern.get_used_cells():
		var map_cell = patternPosition + pattern_cell
		
		# Check map bounds
		if map_cell.x < 0 \
		or map_cell.y < 0 \
		or map_cell.x >= mapSize.x \
		or map_cell.y >= mapSize.y:
			return false

		# Check if something is already placed
		if usedCells.has(map_cell):
			return false
		for neighbor in RandomisedMap.NEIGHBOR_DIRECTIONS:
			if usedCells.has(map_cell + neighbor):
				return false

	return true
