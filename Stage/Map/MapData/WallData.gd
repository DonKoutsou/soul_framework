@tool
extends Resource

class_name WallData

@export var Cracked : bool = false
@export var WallTransform : Transform3D
@export var VariantIndex : int = 0
var collisionShape : CollisionShape3D
