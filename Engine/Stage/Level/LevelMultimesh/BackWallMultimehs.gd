@tool
extends LevelMultimesh
class_name BackWallMultimesh

func _ready() -> void:
	collider = Level.CurrentWallCollider.create_trimesh_shape()
	collider.backface_collision = true

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var spawnAmm : int = 0
	
	if (!cell.HasData("BackWalls")):
		return
	
	for wall in cell.Custom_Data["BackWalls"]:
		var collision = CollisionShape3D.new()
		collision.shape = collider
		collision.transform = wall.scaled_local(Level.CurrentWorldScale)
		AddSpawn(geometry.get_rid(), pos, wall, spawnAmm, collision)
		spawnAmm += 1
	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.BACK_WALLS
