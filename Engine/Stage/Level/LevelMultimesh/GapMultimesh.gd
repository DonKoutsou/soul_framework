@tool
extends LevelMultimesh
class_name GapMultimesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	var CurrentWorldScale = Level.CurrentWorldScale
	collider.size = CurrentWorldScale

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	if (cell.type == CellData.CELLTYPE.GAP):
		var trans = Transform3D(Basis(), realPos)
		var collision = CollisionShape3D.new()
		collision.shape = collider
		var ColliderPos = trans.translated(Vector3(0,Level.CurrentWorldScale.y / 2.0, 0))
		collision.transform = ColliderPos
		
		AddSpawn(geometry.get_rid(), pos, trans, 0, collision)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.GAP

func AddSpot(Data : MapData, pos : Vector3i) -> void:
	var cell = Data.cells[pos]
	cell.spawnFloor = false
	cell.type = CellData.CELLTYPE.GAP
