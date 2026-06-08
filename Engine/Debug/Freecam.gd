extends Node3D

class_name Freecam

@export var MoveLoc : Node3D
@export var Cam : Camera3D

func ProcessInput(event: InputEvent) -> void:
	if (event is InputEventMouseMotion):
		var newrot = Cam.rotation - (Vector3(event.relative.y, event.relative.x, 0) * 0.02)
		newrot.x = clamp(newrot.x, -PI / 2, PI / 2)
		Cam.rotation = newrot
	#if (event.is_action_pressed("move_forward")):
		#global_position += MoveLoc.global_position

func _physics_process(delta: float) -> void:
	var Dir : Vector3 = Vector3.ZERO
	if (Input.is_action_pressed("move_forward")):
		Dir.z -= 2 * delta
	if (Input.is_action_pressed("move_back")):
		Dir.z += 2 * delta
	if (Input.is_action_pressed("look_left")):
		Dir.x -= 2 * delta
	if (Input.is_action_pressed("look_right")):
		Dir.x += 2 * delta
	if (Input.is_action_pressed("DuckLeft")):
		Dir.y -= 2 * delta
	if (Input.is_action_pressed("DuckRight")):
		Dir.y += 2 * delta
	Dir = Dir.rotated(Vector3(0,1,0), Cam.rotation.y)
	position += Dir
