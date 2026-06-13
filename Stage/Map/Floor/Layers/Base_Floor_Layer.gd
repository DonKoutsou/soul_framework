@tool
extends TileMapLayer

class_name BaseFloorLayer

@export var layerType : FloorLayer.LayerType = FloorLayer.LayerType.MAZE
@export var DebugStringColor : Color = Color(1,1,1)

func HandleCell(_cellDat : CellData, _Pos : Vector3i, _map : Map, _tempLayerData : TempLayerGenerationData, _tempData : TempGenerationData) -> void:
	pass

#TODO fix this, we dont need all those separate functions
#----------------------------------------------------------------
func Testtile(pos : Vector2i) -> int:
	var tile_alternate : int = 0
	var rot = GetTileRotationRadians(pos)
	match rot:
		-PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		PI:
			tile_alternate = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
	return tile_alternate

#----------------------------------------------------------------
func GetTileRotationRadians(pos : Vector2i) -> float:
	var rot : float = 0
	
	if is_cell_flipped_h(pos) == false and is_cell_flipped_v(pos) == false:
		rot = 0
	elif is_cell_flipped_h(pos) == true and is_cell_flipped_v(pos) == false:
		rot = -PI/2
	elif is_cell_flipped_h(pos) == false and is_cell_flipped_v(pos) == true:
		rot = PI/2
	elif is_cell_flipped_h(pos) == true and is_cell_flipped_v(pos) == true:
		rot = PI
	return rot

#----------------------------------------------------------------
func GetTileDirection(pos : Vector2i) -> Vector2:
	var Dir : Vector2 = Vector2.RIGHT
	
	if is_cell_flipped_h(pos) == false and is_cell_flipped_v(pos) == false:
		Dir = Vector2.RIGHT
	elif is_cell_flipped_h(pos) == true and is_cell_flipped_v(pos) == false:
		Dir = Vector2.DOWN
	elif is_cell_flipped_h(pos) == false and is_cell_flipped_v(pos) == true:
		Dir = Vector2.UP
	elif is_cell_flipped_h(pos) == true and is_cell_flipped_v(pos) == true:
		Dir = Vector2.LEFT
	return Dir

func GetDebugData(_map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	return DebugData
