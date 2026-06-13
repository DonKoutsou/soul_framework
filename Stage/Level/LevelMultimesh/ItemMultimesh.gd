@tool
extends LevelMultimesh
class_name ItemMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	
	if (!cell.HasData("Item")):
		return
	
	var it : Item = cell.Custom_Data["Item"]
	
	if (cell.type == CellData.CELLTYPE.DUGGABLE):
		return
	
	var matRID = RID()
	
	if it.ModelMat != null:
		matRID = it.ModelMat.get_rid()
	
	var modelRID = it.Model.get_rid()
	if (modelRID.get_id() == 0):
		printerr("Item {0} has wronlgly configured model".format([it.ItemName]))
	
	var spawnPos = Transform3D(Basis().rotated(Vector3(0,0,1), 0.3), Vector3(realPos) + Vector3(0,0.5,0))
	spawnPos = spawnPos.rotated_local(Vector3(0,1,0), r.randf_range(0, PI * 2))
	
	
	AddSpawn(modelRID, pos, spawnPos, 0, null, matRID)


func Proc(delta : float) -> void:
	for pos in spawnList:
		for data in spawnList[pos]:
			var instance : RID = data["Instance"]
			var loc : Transform3D = data["Transform"]
			loc = loc.rotated_local(Vector3(0,1,0), delta * 2)
			data["Transform"] = loc
			RenderingServer.instance_set_transform(instance, loc)

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.ITEMS
