@tool
extends LevelMultimesh
class_name LockMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	
	if (!cell.HasData("Locks")):
		return
	
	var spawnAmm : int = 0
	for lock in cell.Custom_Data["Locks"]:
		AddSpawn(geometry.get_rid(), pos, lock, spawnAmm)
		spawnAmm += 1
	
	if (!cell.HasData("MasterLocks")):
		return
	
	for lock in cell.Custom_Data["MasterLocks"]:
		AddSpawn(geometry.get_rid(), pos, lock, spawnAmm)
		spawnAmm += 1

	
func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.LOCKS

func RemoveSpot(Data : MapData, Pos : Vector3i) -> void:
	var cell : CellData = Data.cells[Pos]
	cell.Custom_Data.erase("Locks")
	cell.Custom_Data.erase("MasterLocks")
	super(Data, Pos)
