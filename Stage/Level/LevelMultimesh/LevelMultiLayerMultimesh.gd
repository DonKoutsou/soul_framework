@tool
extends Node3D
class_name LevelMultiLayerMultimesh

signal Finished

func Proc(delta : float) -> void:
	for g : LevelMultimesh in get_children():
		if (g.Enabled):
			g.Proc(delta)

func Update(Data : MapData, positions : Array[Vector3i], r : RandomNumberGenerator = null) -> void:
	call_deferred("Process", Data, positions, r)

func Process(Data : MapData, positions : Array[Vector3i], r : RandomNumberGenerator = null) -> void:
	#print("Processing {0} children".format([get_child_count()]))
	for g : LevelMultimesh in get_children():
		if (g.Enabled):
			g.Update(Data, positions, r)
			await g.Finished
	Finished.emit()

func GetLayerType() -> LevelMultimeshTypes:
	return get_child(0).GetLayerType()
	

func Clear() -> void:
	for g : LevelMultimesh in get_children():
		g.Clear()

enum LevelMultimeshTypes{
	FLOOR,
	CEILING,
	FALL,
	WATER,
	LAVA,
	GAP,
	STAIRS,
	WALLS,
	BROKEN_WALLS,
	BACK_WALLS,
	TORCH_WALLS,
	DOOR_WALLS,
	CORNERS,
	DOORS,
	LOCKS,
	LIGHT_DOORS,
	LADDERS,
	RECRUITS,
	LOGS,
	ITEMS,
	CHESTS,
	LEVERS,
	MOVABLES,
	PLATES,
	PROJECT_SWITCHES,
	DUGGABLES,
	DUG_DUGGABLES,
	BREAKABLES,
	SOFT_BREAKABLES,
	DECORSTIONS,
	BLOCKING_DECORATION,
}
