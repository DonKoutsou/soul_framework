extends MeshInstance3D

class_name LightPart

@export var DPart : PackedScene
@export var TurnPower : float = 10
@export var SpeedOverride : float = 1.0

var Destination : Node3D
var StaticDestination : Vector3 = Vector3.ZERO
var Aimpoint : Node3D
var FuturePosition : Node3D
var ClampedValues : bool = true
var Accuracy = 0

signal Finished
signal Died

func _ready() -> void:
	Aimpoint = get_child(0)
	FuturePosition = get_child(1)
	if (ClampedValues):
		rotation.x = randf_range(0.4, PI - 0.4)
		rotation.z = randf_range(0.4, PI - 0.4)
	else:
		rotation.x = randf_range(-PI / 2, PI / 2)
		rotation.z = randf_range(0.4, PI - 0.4)
	var dest : Vector3 = StaticDestination
	if (Destination != null):
		dest = Destination.global_position
	Aimpoint.look_at(dest)
	global_rotation.y = Aimpoint.global_rotation.y
	$AudioStreamPlayer3D.pitch_scale = randi_range(5, 12)
	$AudioStreamPlayer3D.volume_db = randf_range(-60, -55)

func Update(delta: float) -> void:
	var dest : Vector3 = StaticDestination
	if (Destination != null):
		dest = Destination.global_position
	if (dest.distance_squared_to(global_position) < 0.01):
		var part = DPart.instantiate() as GPUParticles3D
		if (Destination != null):
			Destination.add_child(part)
		else:
			get_parent().add_child(part)
			part.global_position = global_position
		part.emitting = true
		part.amount = 5
		part.scale = Vector3(0.4,0.4,0.4)
		Died.emit()
		Finished.emit()
		queue_free()
	if (dest.distance_squared_to(global_position) > 40):
		Died.emit()
		queue_free()
		
	Aimpoint.look_at(dest)
	Accuracy += delta * TurnPower
	#print(Aimpoint.global_rotation)
	
	#var forward = global_transform.basis.z
	# Move the node forward
	global_position = global_position.move_toward(FuturePosition.global_position, delta * SpeedOverride)
	global_rotation = Vector3(move_toward(global_rotation.x, Aimpoint.global_rotation.x,delta *  Accuracy), move_toward(global_rotation.y, Aimpoint.global_rotation.y, delta * Accuracy), move_toward(global_rotation.z, Aimpoint.global_rotation.z, delta * Accuracy))
