@tool
extends TileMapLayer

class_name BaseFloorLayer

@export var layerType : FloorLayer.LayerType = FloorLayer.LayerType.MAZE

func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	pass
