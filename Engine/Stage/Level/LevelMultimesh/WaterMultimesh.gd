@tool
extends LevelMultimesh
class_name WaterMultimesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size = Level.CurrentWorldScale

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell : CellData = Data.cells[pos]
	var realPos : Vector3i = Helper.MapToPlayerPosition(pos)
	if (cell.type == CellData.CELLTYPE.WATER):
		var trans : Transform3D = Transform3D(Basis(), Vector3(realPos) + Vector3(0,0.05,0))
		
		var collision : InteractionCollisionShape = InteractionCollisionShape.new()
		collision.Name = InteractionCollisionShape.AreaNames.Water
		collision.shape = collider
		
		#QueueCollider(collision)
		var ColliderPos : Transform3D = trans.translated(Vector3(0,Level.CurrentWorldScale.y / 2.0, 0))
		collision.transform = ColliderPos
		
		AddSpawn(geometry.get_rid(), pos, trans, 0, collision)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.WATER

func AddSpot(Data : MapData, pos : Vector3i) -> void:
	var cell : CellData = Data.cells[pos]
	cell.spawnFloor = false
	cell.type = CellData.CELLTYPE.WATER
