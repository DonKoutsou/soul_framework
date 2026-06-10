extends Node3D

class_name StartingMenuWorld

var mat : StandardMaterial3D

@export var Cam : Camera3D

var CamPos : Array[Transform3D]

signal AnimFinished

func _ready() -> void:
	#mat = $MeshInstance3D6.material_override
	#$Camera3D.position = $Level.SpawnPoint
	for g : Node3D in $CameraPositions.get_children():
		CamPos.append(g.transform)

#var NewValue = 4.0
#
#func _physics_process(delta: float) -> void:
	#var currentvalue = mat.emission_energy_multiplier
	#if (is_equal_approx(currentvalue, NewValue)):
		##while (abs(currentvalue - NewValue) < 1):
		#NewValue = randf_range(1, 4)
	#mat.emission_energy_multiplier = move_toward(currentvalue, NewValue, delta * 10)

func SwitchCameraPos(i : int) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(Cam, "transform", CamPos[i], 1)

func PlayIntro() -> void:
	$AnimationPlayer.play("Intro")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	AnimFinished.emit()
