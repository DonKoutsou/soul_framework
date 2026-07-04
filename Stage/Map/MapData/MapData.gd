@tool
extends Resource

class_name MapData

@export var cells : Dictionary[Vector3i, CellData]

@export var SpawnPoint : Vector3i
@export var SpawnRot : float

@export var Doors : Dictionary[Vector3i, Map.LocationName]
@export var Exits : Dictionary[Vector3i, Map.LocationName]

@export var MapDir : String
@export var level : String
@export var RandomSeed : int
@export var RandomState : int

@export var DecorationProbability : int = 100
@export var MetaData : Dictionary[String, Variant]


func GetCell(pos : Vector3i) -> CellData:
	if (cells.has(pos)):
		return cells[pos]
	return null

func HasCell(pos : Vector3i) -> bool:
	return cells.has(pos)

func get_points_in_square(center: Vector3i, distance: int) -> Array[Vector3i]:
	var points : Array[Vector3i]
	if (cells.has(center)):
		points.append(center)
	for x in range(-distance, distance + 1):
		for z in range(-distance, distance + 1):
			for y in range(-1, 1 + 1):
				# Skip the center point itself
				if x == 0 and z == 0 and y == 0:
					continue
				var loc = center + Vector3i(x, y, z)
				if (cells.has(loc)):
					points.append(loc)

	return points


func SaveRandomState(NewStage : int) -> void:
	RandomState = NewStage
	#print("Saved Random State of {0}".format([NewStage]))

func GetRandomGenerator() -> RandomNumberGenerator:
	var r = RandomNumberGenerator.new()
	r.seed = RandomSeed
	r.set_state(RandomState)
	#print("Created new generator with Seed {0} and State {1}".format([RandomSeed, RandomState]))
	return r
