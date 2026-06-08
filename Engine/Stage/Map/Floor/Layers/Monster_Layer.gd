@tool
extends BaseFloorLayer

class_name MonsterLayer

func GetMonsterSpawnsOnRoom(room : Array) -> Array[Vector2i]:
	var Spawns : Array[Vector2i]
	for g : Vector2i in get_used_cells():
		var ID = get_cell_atlas_coords(g)
		if (ID.x == -1):
			continue
		if (room.has(g)):
			Spawns.append(Vector2i(g.x, g.y))
	return Spawns
