@tool
extends LevelMultimesh
class_name ItemMultimesh

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.cells[pos]
	var realPos = Helper.MapToPlayerPosition(pos)
	
	if (!cell.HasData("Item")):
		return
	
	var it : Item = load(cell.Custom_Data["Item"])
	
	if (cell.type == CellData.CELLTYPE.DUGGABLE):
		return
	
	var matRID = RID()
	
	if it.ModelMat != null:
		matRID = it.ModelMat.get_rid()
	
	var modelRID = it.Model.get_rid()
	if (modelRID.get_id() == 0):
		printerr("Item {0} has wronlgly configured model".format([it.ItemName]))
	
	AddSpawn(modelRID, pos, Transform3D(Basis(), Vector3(realPos) + Vector3(0,0.25,0)), 0, null, matRID)
	

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.ITEMS
