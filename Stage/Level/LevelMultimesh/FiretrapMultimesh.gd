@tool
extends LevelMultimesh
class_name FireTrapMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("Trap")):
		return

	var trap = cell.Custom_Data["Trap"]
	if (trap.TrapType == Map.TrapType.FIRE_TRAP):
		AddSpawn(geometry.get_rid(), pos, trap.TrapTransform, 0)


func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.FIRE_TRAP
