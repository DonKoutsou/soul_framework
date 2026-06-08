@tool
extends LevelMultimesh
class_name SoftBreakablesMultimesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	var aabb = geometry.get_aabb()
	collider.size = aabb.size

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var aabb = geometry.get_aabb()

	var cell = Data.cells[pos]
	
	if (!cell.HasData("SoftBreakable")):
		return
	
	var trans : Transform3D = cell.Custom_Data["SoftBreakable"]
	var collision = InteractionCollisionShape.new()
	collision.shape = collider
	collision.Name = InteractionCollisionShape.AreaNames.Breakable
	collision.transform = trans.translated(Vector3(0,aabb.size.y / 2, 0))
	
	AddSpawn(geometry.get_rid(), pos, trans.translated(Vector3(0,0.1,0)), 0, collision)
	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.SOFT_BREAKABLES

func RemoveSpot(Data : MapData, Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	cell.type = CellData.CELLTYPE.NORMAL
	cell.Custom_Data.erase("SoftBreakable")
	super(Data, Pos)
	#TODO fix
	#Update(Data, false)
