@tool
@abstract
extends Node3D
class_name LevelMultimesh

@export var geometry : Mesh
@export var material_override : Material
var T : Thread
var collider : Shape3D
signal Finished

var Sc : RID
#Array of dictionaries
var spawnList : Dictionary[Vector3i, Array]

func Proc(_delta : float) -> void:
	pass

func _exit_tree() -> void:
	Clear()

func RemoveOldSpawns(positions : Array[Vector3i]) -> void:
	for index : int in range(spawnList.size() - 1, -1, -1):
		var pos : Vector3i = spawnList.keys()[index]
		if (positions.has(pos)):
			continue
			
		for data : Dictionary in spawnList[pos]:
			var rid : RID = data["Instance"]
			RenderingServer.free_rid(rid)
			var col : CollisionShape3D = data["Collision"]
			if (col != null):
				col.queue_free()
		
		spawnList.erase(pos)

func RemoveSpot(_Data : MapData, Pos : Vector3i) -> void:
	if (!spawnList.has(Pos)):
		return
	for data : Dictionary in spawnList[Pos]:
		var rid : RID = data["Instance"]
		RenderingServer.free_rid(rid)
		var col : CollisionShape3D = data["Collision"]
		if (col != null):
			col.queue_free()
	spawnList.erase(Pos)
	

func RemoveIndex(_Data : MapData, pos : Vector3i, index : int) -> void:
	for instanceIndex : int in spawnList[pos].size():
		if (instanceIndex == index):
			var data : Dictionary = spawnList[pos][instanceIndex]
			var rid : RID = data["Instance"]
			RenderingServer.free_rid(rid)
			var col : CollisionShape3D = data["Collision"]
			if (col != null):
				col.queue_free()
			
			spawnList[pos].remove_at(instanceIndex)
			break

func AddSpawn(mesh : RID, pos : Vector3i, loc : Transform3D, index : int, collision : CollisionShape3D = null, matOverride : RID = RID()) -> void:
	if (spawnList.has(pos)):
		if (spawnList[pos].size() > index):
			return
	var Instance : RID = RenderingServer.instance_create()
	
	if (!spawnList.has(pos)):
		spawnList[pos] = []
		
	var data : Dictionary = {}
	data["Instance"] = Instance
	data["Collision"] = collision
	spawnList[pos].append(data)
	if (collision != null):
		QueueCollider(collision)

	RenderingServer.instance_set_base(Instance, mesh)
	RenderingServer.instance_set_scenario(Instance, Sc)
	RenderingServer.instance_set_transform(Instance, loc)
	if (material_override != null):
		RenderingServer.instance_geometry_set_material_override(Instance, material_override.get_rid())
	if (matOverride.get_id() != 0):
		RenderingServer.instance_geometry_set_material_override(Instance, matOverride)

func Update(Data : MapData, positions : Array[Vector3i], r : RandomNumberGenerator = null) -> void:
	Sc = get_world_3d().scenario
	RemoveOldSpawns(positions)
	
	if (T != null):
		call_deferred("AwaitAndStart", Data, positions)
		return
	#M = Mutex.new()
	T = Thread.new()
	T.start(Process.bind(Data, positions, r))
	
	#var Dat = Data.GetDataForLayerType(MultimeshType)

func AwaitAndStart(Data : MapData, positions : Array[Vector3i], r : RandomNumberGenerator = null) -> void:
	if (T != null):
		await Finished
	T = Thread.new()
	T.start(Process.bind(Data, positions, r))

func Process(Data : MapData, positions : Array[Vector3i], r : RandomNumberGenerator = null) -> void:
	for mapPos : Vector3i in positions:
		if (spawnList.has(mapPos)):
			continue
		ProcessPosition(Data, mapPos, r)
	call_deferred("Finish")

@abstract func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void

func Finish() -> void:
	#print("finished updating {0}".format([get_script().get_global_name()]))
	T.wait_to_finish()
	T = null
	Finished.emit()

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.FLOOR

func GetArea() -> Area3D:
	if (get_child_count() == 0):
		return null
	return get_child(0)

func QueueCollider(Collider : Node3D) -> void:
	call_deferred("AddCollider", Collider)

func AddCollider(Collider : Node3D) -> void:
	GetArea().add_child(Collider)

func Clear() -> void:
	var Area : Area3D = GetArea()
	if (Area != null):
		for g : Node3D in Area.get_children():
			g.queue_free()
	RemoveOldSpawns([])

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
	TRANSITIONS,
	FIRE_TRAP,
	HOUSE,
}
