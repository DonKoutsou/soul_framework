@tool
extends Node3D

class_name MeshSpawner

@export var ViewDistanceSquared : float = 20

var Instances : Dictionary[Transform3D, RID]
var staticInstances : Dictionary[Transform3D, RID]
var PlayerPosition : Vector3
var PlayerRotation : Vector3

var threadTaskID : int = -1

#array of RIDs
var spawnedInstanced : Dictionary[Vector3i, Array]

func ClearMeshes() -> void:
	for g in Instances:
		RenderingServer.free_rid(Instances[g])
	for g in staticInstances:
		RenderingServer.free_rid(staticInstances[g])
	Instances.clear()
	staticInstances.clear()

func _exit_tree() -> void:
	for g in Instances:
		RenderingServer.free_rid(Instances[g])
	for g in staticInstances:
		RenderingServer.free_rid(staticInstances[g])
	Instances.clear()
	staticInstances.clear()

func PlayerPositionChanged(NewPos : Vector3, Rot : Vector3) -> void:
	PlayerPosition = NewPos
	PlayerRotation = Rot
	threadTaskID = WorkerThreadPool.add_task(Check)

func PosChanged(NewPos : Vector3, data : MapData) -> void:
	var Positions = get_points_in_square(Helper.PlayerPositionToMap(NewPos), 2)
	for Index in range(spawnedInstanced.size() - 1, -1, -1):
		var pos = spawnedInstanced.keys()[Index]
		if (!Positions.has(pos)):
			for g : RID in spawnedInstanced[pos]:
				RenderingServer.free_rid(g)
			spawnedInstanced.erase(pos)
	
	var Sc = get_world_3d().scenario
	for g in Positions:
		var things = GetMeshesForPosition(g, data)
		for meshData in things:
			for spawnPos in things[meshData]:
				var Instance = RenderingServer.instance_create()
				RenderingServer.instance_set_base(Instance, meshData.get_rid())
				RenderingServer.instance_set_scenario(Instance, Sc)
				RenderingServer.instance_set_transform(Instance, spawnPos)
				
				#RenderingServer.vertex_colo()
				StoreInstance(g, Instance)

func StoreInstance(pos : Vector3i, key : RID) -> void:
	if (spawnedInstanced.keys().has(pos)):
		spawnedInstanced[pos].append(key)
	else:
		var ar : Array = []
		ar.append(key)
		spawnedInstanced[pos] = ar

#array of transform 3D
func GetMeshesForPosition(pos : Vector3i, data : MapData) -> Dictionary[Mesh, Array]:
	var List : Dictionary[Mesh, Array]
	var floorMesh = get_parent().get_node("Floors").multimesh.mesh
	if (data.Floors.has(pos)):
		List[floorMesh] = [data.Floors[pos]]
	return List
		

func get_points_in_square(center: Vector3i, distance: int) -> Array[Vector3i]:
	var points : Array[Vector3i]
	points.append(center)
	for x in range(-distance, distance + 1):
		for z in range(-distance, distance + 1):
			# Skip the center point itself
			if x == 0 and z == 0:
				continue

			points.append(center + Vector3i(x, 0, z))

	return points

func SpawnMeshes(M : Dictionary[Mesh, Array], positionalHide : bool) -> void:
	var Sc = get_world_3d().scenario
	for mesh in M:
		for MData : MeshData in M[mesh]:
			var Instance = RenderingServer.instance_create()
			RenderingServer.instance_set_base(Instance, mesh.get_rid())
			RenderingServer.instance_set_scenario(Instance, Sc)
			RenderingServer.instance_set_transform(Instance, MData.Transform)
			if (MData.MatOverride != null):
				RenderingServer.instance_set_surface_override_material(Instance, 0, MData.MatOverride)
			#RenderingServer.instance_geometry_set_visibility_range(Instance, 0, 20, 0, 0,RenderingServer.VISIBILITY_RANGE_FADE_SELF)
			if (positionalHide):
				Instances[MData.Transforms] = Instance
			else:
				staticInstances[MData.Transform] = Instance

func RemoveMesh(Loc : Transform3D) -> void:
	var Instance : RID
	if (Instances.has(Loc)):
		Instance = Instances[Loc]
	else: if (staticInstances.has(Loc)):
		Instance = staticInstances[Loc]
	else:
		return
		
	RenderingServer.free_rid(Instance)
	Instances.erase(Loc)

func ToggleMeshVisibility(Loc : Transform3D, T : bool) -> void:
	var Instance : RID
	if (Instances.has(Loc)):
		Instance = Instances[Loc]
	else: if (staticInstances.has(Loc)):
		Instance = staticInstances[Loc]
	else:
		return

	RenderingServer.instance_set_visible(Instance, T)
# SetInstanceCustomData(Loc : Transform3D, Data : Color) -> void:
	#RenderingServer.multimesh_instance_set_custom_data() 

func Check() -> void:
	for InstancePosition in Instances:

		#var Dot = PlayerRotation.dot(InstancePosition.origin.direction_to(PlayerPosition))
		#var WantedDot = cos(deg_to_rad(50))
		#call_deferred("ToggleMeshVisibility", InstancePosition, InstancePosition.origin.distance_squared_to(PlayerPosition) < ViewDistanceSquared and Dot < WantedDot)
		call_deferred("ToggleMeshVisibility", InstancePosition, InstancePosition.origin.distance_squared_to(PlayerPosition) < ViewDistanceSquared)
	call_deferred("CheckingFinished")
	
	
func CheckingFinished() -> void:
	WorkerThreadPool.wait_for_task_completion(threadTaskID)
