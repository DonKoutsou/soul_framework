@tool
extends LevelMultimesh
class_name CeilingMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var realPos = Helper.MapToPlayerPosition(pos)
	var cell = Data.cells[pos]
	if (cell.spawnCeiling and !cell.floorAsCeiling):
		var Trans = Transform3D(Basis().rotated(Vector3(1,0,0), PI), realPos + Vector3i(0,Level.CurrentWorldScale.y,0))
		AddSpawn(geometry.get_rid(), pos, Trans, 0)
		
		var instance = spawnList[pos][0]["Instance"]
		var dat : int = 0
		if (cell.CrackedCeiling):
			dat = 2

		RenderingServer.instance_geometry_set_shader_parameter(instance, "variant_index", dat)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.CEILING
