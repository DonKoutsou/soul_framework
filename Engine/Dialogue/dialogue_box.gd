extends ColorRect

class_name DialogueBox

@export var DialogueLabel : Label

signal Toggled(t : bool)

var TextSpeed : float = 1.0
var TimerSpeed : float = 0.0
var TextTween : Tween
var WaitTimer : SceneTreeTimer

func _ready() -> void:
	visible = false
	set_physics_process(false)

var DialoguesToDo : Array[String]

func _physics_process(delta: float) -> void:
	if (Input.is_anything_pressed()):
		TextSpeed = 10
		TimerSpeed = 10
	else:
		TextSpeed = 1
		TimerSpeed = 0
	
	if (is_instance_valid(TextTween) and TextTween.is_valid()):
		TextTween.custom_step(delta * TextSpeed)
	
	if (is_instance_valid(WaitTimer)):
		WaitTimer.time_left -= TimerSpeed * delta
	
	
func DoDialogue(DialogueList : DialogueContainer) -> void:
	var Dialogue = DialogueList.Dialogues.pop_front()
	DialoguesToDo = DialogueList.Dialogues
	visible = true
	set_physics_process(true)
	Toggled.emit(true)
	modulate.a = 0
	var VisibilityTween = create_tween()
	VisibilityTween.tween_property(self, "modulate", Color(1,1,1,1), 0.5)
	WorldTimeManager.Instance.StopTime()
	ShowDialogue(Dialogue)

func ShowDialogue(Dialogue : String) -> void:
	TextTween = create_tween()
	DialogueLabel.text = Dialogue
	DialogueLabel.visible_characters = 0
	TextTween.tween_property(DialogueLabel, "visible_characters", Dialogue.length(), Dialogue.length() / 10.0)
	TextTween.finished.connect(DialogueFinished)

func DialogueFinished() -> void:
	WaitTimer = get_tree().create_timer(1, false, false)
	await WaitTimer.timeout
	#await Helper.Instance.wait(1)
	if (DialoguesToDo.size() > 0):
		ShowDialogue(DialoguesToDo.pop_front())
	else:
		var VisibilityTween = create_tween()
		VisibilityTween.tween_property(self, "modulate", Color(1,1,1,0), 0.5)
		VisibilityTween.finished.connect(DialogueVisibilityEnded)

func DialogueVisibilityEnded() -> void:
	WorldTimeManager.Instance.StartTime()
	visible = false
	set_physics_process(false)
	Toggled.emit(false)
