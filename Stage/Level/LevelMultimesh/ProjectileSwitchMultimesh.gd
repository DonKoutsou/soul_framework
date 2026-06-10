@tool
extends LevelMultimesh
class_name ProjectileSwitchMultimesh


func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size = geometry.get_aabb().size

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.GetCell(pos)
	
	if (!cell.HasData("ProjectileSwitch")):
		return
	
	var Offset = geometry.get_aabb().position + (collider.size / 2)

	var realPos = Helper.MapToPlayerPosition(pos)
	var SwitchData = cell.Custom_Data["ProjectileSwitch"]
	var t = Transform3D(Basis(), realPos)
	
	var Collision = ProjectileSwitchCollision.new()
	Collision.shape = collider
	Collision.Name = InteractionCollisionShape.AreaNames.Projectile_Switch
	Collision.SwitchInfo = SwitchData
	var ColliderPos = t.translated(Offset)
	Collision.transform = ColliderPos
	
	AddSpawn(geometry.get_rid(), pos, t, 0, Collision)
	
	var state : float = 0.0
	var variantIndex : int = 0
	if (SwitchData.State):
		state = 1.0
	
	variantIndex = SwitchData.Info.Element
	
	var instance = spawnList[pos][0]["Instance"]
	RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", variantIndex)
	RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_emission_energy_multiplier", state)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.PROJECT_SWITCHES

func UpdateSwitch(Data : MapData, Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	var SwitchData : ProjectileSwitchData = cell.Custom_Data["ProjectileSwitch"]
	
	var data = spawnList[Pos][0]
	var Instance : RID = data["Instance"]
	
	var state : float = 0.0
	var variantIndex : int = 0
	if (SwitchData.State):
		state = 1.0
	
	variantIndex = SwitchData.Info.Element
	
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "variant_index", variantIndex)
	RenderingServer.instance_geometry_set_shader_parameter(Instance, "instance_emission_energy_multiplier", state)
