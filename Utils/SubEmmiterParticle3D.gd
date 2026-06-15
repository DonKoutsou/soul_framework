extends GPUParticles3D

class_name SubEmmiterParticle3D

@export var SubEmmiters : Array[GPUParticles3D]

func _ready() -> void:
	if (one_shot):
		finished.connect(queue_free)

func StartEmmision() -> void:
	restart()
	emitting = true
	for g in SubEmmiters:
		g.restart()
		g.emitting = true
