@tool
extends LevelMultimesh
class_name BlockingDecorationMultimesh

@export var CustomCollision : Mesh
@export var RandomiseRotation : bool = true


func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size = Level.CurrentWorldScale
	
	if (CustomCollision != null):
		collider = CustomCollision.create_trimesh_shape()
		collider.backface_collision = true


func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.GetCell(pos)
	
	if (!cell.HasData("BlockingDeco")):
		return

	var collision = CollisionShape3D.new()
	collision.shape = collider
	var ColliderPos = cell.Custom_Data["BlockingDeco"].translated(Vector3(0,Level.CurrentWorldScale.y / 2.0, 0))
	collision.transform = ColliderPos
	AddSpawn(geometry.get_rid(), pos, cell.Custom_Data["BlockingDeco"], 0, collision)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.BLOCKING_DECORATION
