extends Control

class_name ButtonPrompt

@export var InputName : String
@export var Tooltip : String = "Press"
@export var PlaySound : bool = true
@export_group("Nodes")
@export var Prompt : ButtonPromptSprite
@export var Lab : Label
@export var PromptText : Label

signal Finished
signal PromptPressed

func _ready() -> void:
	Lab.text = Tooltip
	Prompt.ACTION = InputName

func ProcessInput(event: InputEvent) -> void:
	if (event.is_action_pressed(InputName)):
		PromptPressed.emit()
		set_process_input(false)
		Pressed()

func Pressed() -> void:
	var tw = create_tween()
	#tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(Prompt, "scale", Vector2(0.25, 0.25), 0.1)
	
	if (PlaySound):
		AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP)
	$GPUParticles2D.emitting = true
	await tw.finished
	
	var tw2 = create_tween()
	#tw2.set_ease(Tween.EASE_OUT)
	tw2.set_trans(Tween.TRANS_BOUNCE)
	tw2.tween_property(Prompt, "scale", Vector2(0.4, 0.4), 0.1)
	
	
	await tw2.finished
	
	var tw3 = create_tween()
	#tw3.set_ease(Tween.EASE_IN)
	tw3.set_trans(Tween.TRANS_BOUNCE)
	tw3.tween_property(Prompt, "scale", Vector2(0.35, 0.35), 0.1)
	
	
	await tw3.finished
	
	Finished.emit()
	queue_free()
