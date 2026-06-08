@tool
extends LevelMultimesh
class_name WallMultimesh

@export var alt_Geomatry : Array[Mesh]

func _ready() -> void:
	collider = Level.CurrentWallCollider.create_trimesh_shape()
	collider.backface_collision = true

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.GetCell(pos)
	
	if (!cell.HasData("Walls")):
		return
	
	var spawnAmm : int = 0
	for wall : WallData in cell.Custom_Data["Walls"]:
		var collision = CollisionShape3D.new()
		collision.shape = collider
		collision.transform = wall.WallTransform.scaled_local(Level.CurrentWorldScale)
		wall.collisionShape = collision
		
		if (wall.VariantIndex == 0):
			AddSpawn(geometry.get_rid(), pos, wall.WallTransform, spawnAmm, collision)
		if (wall.VariantIndex == 1):
			AddSpawn(alt_Geomatry[0].get_rid(), pos, wall.WallTransform, spawnAmm, collision)
		if (wall.VariantIndex == 2):
			AddSpawn(alt_Geomatry[1].get_rid(), pos, wall.WallTransform, spawnAmm, collision)
		
		var instance = spawnList[pos][spawnAmm]["Instance"]

		RenderingServer.instance_geometry_set_shader_parameter(instance, "cracked", wall.Cracked)
			
		RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", wall.VariantIndex)
		spawnAmm += 1

func RemoveIndex(Data: MapData,  pos : Vector3i, index : int) -> void:
	super(Data, pos, index)
	var cell = Data.GetCell(pos)
	var wallDat : WallData = cell.Custom_Data["Walls"][index]
	wallDat.collisionShape.queue_free()
	cell.Custom_Data["Walls"].erase(wallDat)
	

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.WALLS
