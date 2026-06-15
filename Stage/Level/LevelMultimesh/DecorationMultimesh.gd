@tool
extends LevelMultimesh
class_name DecorationMultimesh

@export var RandomiseRotation : bool = true
@export var SnapRotation : bool = false
@export var AllowOnCeiling : bool = false

func ProcessPosition(Data : MapData, pos : Vector3i, r : RandomNumberGenerator = null) -> void:

	var cell = Data.cells[pos]
	var ammSpawned : int = 0
	if (cell.Custom_Data.has("Decorations")):
		var decos : Array = cell.Custom_Data["Decorations"]
		for decoT : Transform3D in decos:
			var Trans = decoT
			if (RandomiseRotation):
				#M.lock()
				if (SnapRotation):
					var rot = Helper.GetRandomRotationSnapped(r)
					Trans = Trans.rotated_local(Vector3(0,1,0), rot)
				else:
				
					Trans = Trans.rotated_local(Vector3(0,1,0), r.randf_range(-PI * 2, PI * 2))
				#M.unlock()
			if (AllowOnCeiling and cell.spawnCeiling):
				Trans = Trans.rotated_local(Vector3(0,0,1), PI)
				Trans = Trans.translated_local(Vector3(0, -Level.CurrentWorldScale.y + 0.2, 0))
			
			AddSpawn(geometry.get_rid(), pos, Trans, ammSpawned)
			var instance = spawnList[pos][ammSpawned]["Instance"]
			RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", pos.x + pos.y + pos.z)
			ammSpawned += 1


func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.DECORSTIONS
