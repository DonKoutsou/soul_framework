extends Node2D

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
		if (data.is_point_disabled(pointIndex)):
			Astar.set_point_disabled(pointID)
	
	for pointIndex in data.get_point_count():
		var pointID = PreviousIndexAmm + pointIndex
		for connection in data.get_point_connections(pointIndex):
			Astar.connect_points(pointID, PreviousIndexAmm + connection)
	



func _draw() -> void:
	const cols : Array[Color] = [Color(1,0,0), Color(0,1,0), Color(0,0,1), Color(0.85, 0.444, 0.0, 1.0), Color(0.736, 1.0, 0.406, 1.0)]
	
	var par : Map = get_parent()
	var fl = par.GetFloor(0)
	var layer = fl.GetLayer(FloorLayer.LayerType.MAZE)
	for pointId in Astar.get_point_count():
		if (Astar.is_point_disabled(pointId)):
			continue
		var connections = Astar.get_point_connections(pointId)
		var pont = Astar.get_point_position(pointId)
		var g = Helper.Vector3ITo2(pont)
		var gGlobal = layer.map_to_local(g) + Vector2(0, pont.y * 320)
		for connection in connections:
			if (Astar.is_point_disabled(connection)):
				continue
			var pointPos = Astar.get_point_position(connection)
			var twoDPos = Helper.Vector3ITo2(pointPos)
			var localPos = layer.map_to_local(twoDPos)
			var globalPos = localPos + Vector2(0, pointPos.y * 320)
			
			draw_line(gGlobal, globalPos, cols[wrap(pointPos.y, 0, cols.size())])
