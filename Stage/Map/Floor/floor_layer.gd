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
