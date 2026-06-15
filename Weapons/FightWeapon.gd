extends Node3D

class_name FightWeapon

@export var DamageBuff : GPUParticles3D
@export var SpeedBuff : GPUParticles3D
@export var spark: SubEmmiterParticle3D
@export var Impact : GPUParticles3D
@export var HandPlacement : Node3D
@export var wepSound : AudioManager.Sound = AudioManager.Sound.SWORD_CLASH

func Sparks() -> void:
	AudioManager.Instance.PlaySound(wepSound, -5, 0.3)

	spark.StartEmmision()

func DoImpact() -> void:
	Impact.restart()
	Impact.emitting = true

func ToggleDamageBuff(t : bool) -> void:
	DamageBuff.emitting = t
	
func ToggleSeedBuff(t : bool) -> void:
	SpeedBuff.emitting = t
