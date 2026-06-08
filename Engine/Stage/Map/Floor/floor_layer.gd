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

var Layers : Array[TileMapLayer]


func _ready() -> void:
	for g in LayerType.keys().size():
		var Path = NodePath(LayerType.keys()[g])
		var Layer : TileMapLayer = get_node(Path)
		Layers.append(Layer)

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

func GetLayer(Type : LayerType) -> TileMapLayer:
	return Layers[Type]
