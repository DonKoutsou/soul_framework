@tool
extends Node2D

class_name MapEditorDebugCam

var mapParent : Map

func _draw() -> void:
	var camPos = EditorInterface.get_editor_viewport_3d().get_camera_3d().global_position
	var camFloorIndex = floor(camPos.y / mapParent.WorldScale.y)
	var camFloor = mapParent.GetFloor(camFloorIndex)
	var camY = 0
	if (camFloor !=null):
		camY = camFloor.position.y
	
	var multiPlier = Vector2(16, 16) / Vector2(mapParent.WorldScale.x, mapParent.WorldScale.z)
	#Add 1 to move it to center of tile
	var TwDCamPos = (Vector2(camPos.x + 1, camPos.z + 1) * multiPlier) + Vector2(0, camY)
	
	draw_circle(TwDCamPos, 2, Color(1,0,0))
	
	var camRot = -EditorInterface.get_editor_viewport_3d().get_camera_3d().rotation.y - (PI * 0.5)
	draw_arc(TwDCamPos, 10, (-PI * 0.2) + camRot,(PI * 0.2) + camRot, 5, Color(1,0,0), 5)
