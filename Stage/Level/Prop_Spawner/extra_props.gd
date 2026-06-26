@tool
extends Node3D

signal Updated()

#func _enter_tree() -> void:
	#for g in get_children():
		#if (g is MoveNotificator):
			#g.Moved.connect(ChildMoved)
		#else:
			#g.set_script(load("res://Scripts/MoveNotificator.gd"))
			#g.Moved.connect(ChildMoved)
			
func _on_child_entered_tree(node: Node) -> void:
	if (node is MoveNotificator):
		node.Moved.connect(ChildMoved)
	else:
		node.set_script(load("res://Engine/Stage/Level/Prop_Spawner/MoveNotificator.gd"))
		node.Moved.connect(ChildMoved)
	Updated.emit()


func _on_child_exiting_tree(node: Node) -> void:
	node.Moved.disconnect(ChildMoved)
	Updated.emit()

func ChildMoved() -> void:
	Updated.emit()
