@tool
extends LevelMultimesh
class_name BreakablesMultimesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	var aabb = geometry.get_aabb()
	collider.size = aabb.size
	
func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("Breakable")):
		return
	
	var aabb = geometry.get_aabb()
	var Offset = aabb.position
	
	var trans : Transform3D = cell.Custom_Data["Breakable"]
	
	var Collision = InteractionCollisionShape.new()
	Collision.shape = collider
	Collision.Name = InteractionCollisionShape.AreaNames.Breakable
	Collision.transform = trans.translated(Offset)
	AddSpawn(geometry.get_rid(), pos, trans.translated(Vector3(0,0.1,0)), 0, Collision)
	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.BREAKABLES

func RemoveSpot(Data : MapData, Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	cell.type = CellData.CELLTYPE.NORMAL
	cell.Custom_Data.erase("Breakable")
	super(Data, Pos)
	#TODO fix
	#Update(Data, false)
