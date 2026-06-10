extends Control

class_name AssetPreloader

signal finished

func _ready() -> void:
	SearchChildren(self)
	
	Helper.Instance.CallLater(Remove, 1)

func Remove() -> void:
	queue_free()
	finished.emit()

func SearchChildren(N : Node) -> void:
	for g in N.get_children():
		if (g is GPUParticles3D):
			g.emitting = true
		if (g is GPUParticles2D):
			g.emitting = true
		
		SearchChildren(g)
