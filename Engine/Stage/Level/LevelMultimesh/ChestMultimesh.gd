@tool
extends LevelMultimesh
class_name ChestMultimesh


func _ready() -> void:
	collider = BoxShape3D.new()

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("Chest")):
		return
	
	var Offset = geometry.get_aabb().position + (collider.size / 2)
	
	var data : ChestData = cell.Custom_Data["Chest"]
	var Trans = data.ChestTransform
	
	var Collision = ChestCollisionShape.new()
	Collision.shape = collider
	Collision.ChestDat = data
	Collision.Name = InteractionCollisionShape.AreaNames.Chest
	Collision.transform = Trans.translated(Offset)
	
	AddSpawn(geometry.get_rid(), pos, Trans, 0, Collision)
	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.CHESTS
