@tool
extends CollisionShape3D

class_name InteractionCollisionShape

@export var Name : AreaNames

func _ready() -> void:
	debug_color = Color(1,0,0,0.42)

enum AreaNames{
	Door,
	Lantern,
	Water,
	Lava,
	Lever,
	Bonfire,
	Char,
	Pressure_Plate,
	Projectile_Switch,
	Movable,
	Light_Door,
	Chest,
	Breakable,
}
