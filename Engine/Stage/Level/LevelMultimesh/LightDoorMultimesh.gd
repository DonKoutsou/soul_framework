@tool
extends LevelMultimesh
class_name LightDoorMultimesh

func _ready() -> void:
	collider = Level.CurrentWallCollider.create_trimesh_shape()
	collider.backface_collision = true

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	if cell.HasData("LightDoor"):
		var DoorDat = cell.Custom_Data["LightDoor"]
		var Trans = DoorDat.DoorTransform
		var d = DoorDat.StoredLight / 20.0
		#multimesh.set_instance_custom_data(g, Color(d,0,0))
		var collision = LightDoorCollision.new()
		collision.Name = LightDoorCollision.AreaNames.Light_Door
		collision.DoorDat = DoorDat
		collision.shape = collider
		collision.transform = Trans
		collision.disabled = !DoorDat.DoorState
		
		if (DoorDat.DoorState):
			AddSpawn(geometry.get_rid(), pos, Trans, 0, collision)
		else:
			AddSpawn(geometry.get_rid(), pos, Trans.translated(Vector3i(0,-100,0)), 0, collision)

		var instance = spawnList[pos][0]["Instance"]
		RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_emission_energy_multiplier", d)


func UpdateLightDoorLight(Data : MapData ,pos : Vector3i) -> void:
	var cell = Data.cells[pos]
	var DoorDat = cell.Custom_Data["LightDoor"]
	var d = DoorDat.StoredLight / 20.0
	var instance = spawnList[pos][0]["Instance"]
	RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_emission_energy_multiplier", d)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.LIGHT_DOORS

func GetLightDoorCenterPoint(Data : MapData ,Pos : Vector3i) -> Vector3:
	var cell = Data.cells[Pos]
	var DoorDat = cell.Custom_Data["LightDoor"]
	var Doortrans = DoorDat.DoorTransform
	var Oppositecell = Data.cells[DoorDat.OpossiteDoorMapPosition]
	var OpossiteDoorDat = Oppositecell.Custom_Data["LightDoor"]
	var OppositeDoorTrans = OpossiteDoorDat.DoorTransform
	var Dif = (OppositeDoorTrans.origin - Doortrans.origin) / 2
	return Doortrans.origin + Dif

func ToggleLightDoor(Data : MapData ,Pos : Vector3i) -> void:
	var cell = Data.cells[Pos]
	var DoorDat = cell.Custom_Data["LightDoor"]
	var oppositeCell = Data.cells[DoorDat.OpossiteDoorMapPosition]
	var OppositeDoorDat = oppositeCell.Custom_Data["LightDoor"]
	
	RemoveSpot(Data, Pos)
	RemoveSpot(Data, DoorDat.OpossiteDoorMapPosition)
	
	DoorDat.DoorState = !DoorDat.DoorState
	OppositeDoorDat.DoorState = !OppositeDoorDat.DoorState
	
	#TODO fix
	#Update(Data, , false)
