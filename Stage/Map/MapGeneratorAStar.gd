extends RefCounted

class_name MapGeneratorAstar

var Astar : AStar3D = AStar3D.new()


func Clear() -> void:
	Astar.clear()

func Connect(pos1 : Vector3i, pos2 : Vector3i) -> void:
	var pos1ID = Astar.get_closest_point(pos1)
	var pos2ID = Astar.get_closest_point(pos2)
	
	Astar.connect_points(pos1ID, pos2ID)
	print("Created connection at {0} and {1}".format([pos1, pos2]))

func Add(data : AStar3D) -> void:
	var PreviousIndexAmm = Astar.get_point_count()
	for pointIndex in data.get_point_count():
		var pointPos = data.get_point_position(pointIndex)
		var pointID = PreviousIndexAmm + pointIndex
		Astar.add_point(pointID, pointPos, 1)
	
	for pointIndex in data.get_point_count():
		var pointID = PreviousIndexAmm + pointIndex
		for connection in data.get_point_connections(pointIndex):
			Astar.connect_points(pointID, PreviousIndexAmm + connection)
	
