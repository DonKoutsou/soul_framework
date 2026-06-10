@tool
extends LevelMultimesh
class_name LeverMultimesh


func _ready() -> void:
	collider = BoxShape3D.new()
	call_deferred("UpdateColliderSize")
	
func UpdateColliderSize() -> void:
	collider.size = geometry.get_aabb().size

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var Offset = geometry.get_aabb().position + (collider.size / 2)
	var cell = Data.GetCell(pos)
	if (cell.Custom_Data.has("Lever")):
		var leverData : LeverData = cell.Custom_Data["Lever"]
		var Info : LeverCallInfo = leverData.Info
		
		var Collision = LeverCollision.new()
		Collision.shape = collider
		Collision.Name = InteractionCollisionShape.AreaNames.Lever
		var ColliderPos = leverData.Trans
		if (!leverData.State):
			ColliderPos.origin += Offset.rotated(Vector3(0,1,0), ColliderPos.basis.orthonormalized().get_euler().y)
		else:
			ColliderPos.origin -= Offset.rotated(Vector3(0,1,0), ColliderPos.basis.orthonormalized().get_euler().y)
		
		Collision.transform = ColliderPos
		#Collision.position += Offset
		Collision.LeverInfo = leverData
		
		AddSpawn(geometry.get_rid(), pos, leverData.Trans, 0, Collision)
		
		var instance = spawnList[pos][0]["Instance"]
			
		RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_alpha_mask_switch", Info.IsMissingPart)
		
		if (Info is GlobalLeverCallInfo):
			RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_use_color_switch", Info.UseColor)
			RenderingServer.instance_geometry_set_shader_parameter(instance, "instance_mask_color", Global_Manager.GetGlobalColor(Info.PrimaryGlobal))
			

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.LEVERS
