@tool
extends MeshInstance3D

class_name MoveNotificator

signal Moved

func _notification(what: int) -> void:
	if (what == NOTIFICATION_TRANSFORM_CHANGED):
		Moved.emit()
		#print("moved")
	#print(what)
