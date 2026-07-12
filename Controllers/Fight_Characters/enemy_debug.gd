extends Label3D

@onready var enemy_fighter: Enemy = $".."

func _physics_process(delta: float) -> void:
	text = var_to_str(floor(enemy_fighter.ControllingCharacter.Fatigue))
