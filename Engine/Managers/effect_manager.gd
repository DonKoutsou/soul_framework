extends Node3D

class_name EffectManager

@export var EffectCatalogue : Dictionary[Effect, String]

enum Effect{
	DEATH,
	DUST,
}

static var Instance : EffectManager

func _ready() -> void:
	Instance = self

func SpawnEffect(Pos : Vector3, effectType : Effect) -> void:
	var effectInstance = load(EffectCatalogue[effectType]).instantiate()
	add_child(effectInstance)
	effectInstance.position = Pos
	effectInstance.emitting = true
	effectInstance.finished.connect(EffectFinished.bind(effectInstance))
	AudioManager.Instance.PlaySound(AudioManager.Sound.MAGIC, -15, 0.1, 0.8, true)
	
func EffectFinished(effect : Node) -> void:
	effect.queue_free()
