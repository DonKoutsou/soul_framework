extends Node3D

class_name BaseTrap

signal Killed
var PlayerSpawned : bool = false

@export var Element : ProjectileSwitchData.SwitchElement
@export var Area : Area3D

func TogglePlayerEffect(t : bool) -> void:
	PlayerSpawned = !t
	Area.set_collision_mask_value(3, t)
	Area.set_collision_layer_value(3, t)

func ToggleEnemyEffect(t : bool) -> void:
	Area.set_collision_mask_value(9, t)
	Area.set_collision_layer_value(9, t)

func Toggle(t : bool) -> void:
	set_physics_process(t)

func DestroySelf() -> void:
	queue_free()
	Killed.emit()

func Update(_delta : float) -> void:
	pass
