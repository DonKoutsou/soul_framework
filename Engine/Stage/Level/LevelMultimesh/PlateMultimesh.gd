@tool
extends LevelMultimesh
class_name PlateMultimesh

func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size = geometry.get_aabb().size

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("Plate")):
		return
	
	var Offset = geometry.get_aabb().position + (collider.size / 2)
	var realPos = Helper.MapToPlayerPosition(pos)

	var PlateData = cell.Custom_Data["Plate"]
	var t = Transform3D(Basis(), realPos).translated(Vector3(0,0.1,0))
	
	var state : float = 0.0
	var variantIndex : int = 0
	if (PlateData.State):
		state = 1.0
	
	variantIndex = PlateData.Info.Element
	
	var Collision = PlateCollision.new()
	Collision.shape = collider
	Collision.Name = InteractionCollisionShape.AreaNames.Pressure_Plate
	var ColliderPos = t
	ColliderPos.origin += Offset
	Collision.transform = ColliderPos
	Collision.PlateInfo = PlateData.Info
	
	AddSpawn(geometry.get_rid(), pos, t, 0, Collision)
	var instance = spawnList[pos][0]["Instance"]
	RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", variantIndex)
	RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_emission_energy_multiplier", state)

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.PLATES

func UpdatePlate(Data : MapData, Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	var plateData : PreassuerPlateData = cell.Custom_Data["Plate"]
	
	var data = spawnList[Pos][0]
	var Instance : RID = data["Instance"]
	
	var state : float = 0.0
	var variantIndex : int = 0
	if (plateData.State):
		state = 1.0
	
	variantIndex = plateData.Info.Element
	
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "variant_index", variantIndex)
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "instance_emission_energy_multiplier", state)
