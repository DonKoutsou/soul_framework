@tool
extends LevelMultimesh
class_name HouseMultimesh

@export var CustomCollision : Mesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size =Level.CurrentWorldScale
	
	if (CustomCollision != null):
		collider = CustomCollision.create_trimesh_shape()
		collider.backface_collision = true


func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("House")):
		return
	
	var trans : Transform3D = cell.Custom_Data["House"]

	var collision = CollisionShape3D.new()
	collision.shape = collider
	var ColliderPos = trans.translated(Vector3(0,Level.CurrentWorldScale.y / 2.0, 0)).rotated_local(Vector3(0,1,0), -PI / 2.0)
	collision.transform = ColliderPos
	#collision.scale = Level.CurrentWorldScale
	AddSpawn(geometry.get_rid(), pos, trans, 0, collision)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.HOUSE
