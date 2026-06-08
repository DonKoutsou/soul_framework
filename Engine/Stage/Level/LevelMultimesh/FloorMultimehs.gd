@tool
extends LevelMultimesh
class_name FloorMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var spawnAmm : int = 0
	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	if (cell.spawnFloor):
		var Trans = Transform3D(Basis(), realPos)
		AddSpawn(geometry.get_rid(), pos, Trans, spawnAmm)
		
		var instance = spawnList[pos][spawnAmm]["Instance"]

		RenderingServer.instance_geometry_set_shader_parameter(instance, "cracked", cell.CrackedFloor)
		spawnAmm += 1

	if (cell.floorAsCeiling):
		var Trans = Transform3D(Basis().rotated(Vector3(1,0,0), PI), realPos + Vector3i(0,Level.CurrentWorldScale.y,0))
		AddSpawn(geometry.get_rid(), pos, Trans, spawnAmm)
		var instance = spawnList[pos][spawnAmm]["Instance"]

		RenderingServer.instance_geometry_set_shader_parameter(instance, "cracked", cell.CrackedCeiling)


func AddSpot(Data : MapData, pos : Vector3i) -> void:
	var cell = Data.GetCell(pos)
	cell.spawnFloor = true

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.FLOOR
