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
	
	var alt_tile = get_cell_alternative_tile(pos)

	# Test for the engine's built-in transform flags
	var flip_h = alt_tile & TileSetAtlasSource.TRANSFORM_FLIP_H > 0
	var flip_v = alt_tile & TileSetAtlasSource.TRANSFORM_FLIP_V > 0
	var transpose = alt_tile & TileSetAtlasSource.TRANSFORM_TRANSPOSE > 0

	match [flip_v, flip_h, transpose]:
		[false, false, false]: rot = 0.0   # No rotation
		[true, true, false]: rot = PI   # 180 degrees
		[true, false, true]: rot = PI / 2  # 90 degrees clockwise
		[false, true, true]: rot = -PI / 2   # 270 degrees clockwise (or -90)
		
	return rot


#----------------------------------------------------------------
func GetTileDirection(pos : Vector2i) -> Vector2:
	var Dir : Vector2 = Vector2.RIGHT
	
	var alt_tile = get_cell_alternative_tile(pos)

	# Test for the engine's built-in transform flags
	var flip_h = alt_tile & TileSetAtlasSource.TRANSFORM_FLIP_H > 0
	var flip_v = alt_tile & TileSetAtlasSource.TRANSFORM_FLIP_V > 0
	var transpose = alt_tile & TileSetAtlasSource.TRANSFORM_TRANSPOSE > 0

	match [flip_v, flip_h, transpose]:
		[false, false, false]: Dir = Vector2.RIGHT   # No rotation
		[true, true, false]: Dir = Vector2.LEFT   # 180 degrees
		[true, false, true]: Dir = Vector2.DOWN  # 90 degrees clockwise
		[false, true, true]: Dir = Vector2.UP   # 270 degrees clockwise (or -90)
		
	return Dir

func GetDebugData(_map : Map, _floorIndex : int) -> Dictionary[String, Variant]:
	var DebugData : Dictionary[String, Variant] = {
		"Texts" : {},
		"Lines" : [],
	}
	return DebugData
