extends Control

class_name TutorialTextPrompt

@export var TutorialPanel : PanelContainer
@export var Title : Label
@export var Text : Label
@export var LeaveButton : Button

signal Ended

func _ready() -> void:
	call_deferred("Pop")
	UiSoundManager.Instance.Refresh()

func SetTexts(TutorialTitle : String, TutorialText : String) -> void:
	var FinalText : String = wrap_string(TutorialText, 70)

	Title.text = TutorialTitle
	Text.text = FinalText

func wrap_string(text: String, max_length: int = 40) -> String:
	var words = text.split(" ")
	var current_line = ""
	var result = ""
	for word in words:
		# +1 due to the added space
		if current_line.length() + word.length() + 1 > max_length:
			result += current_line.strip_edges() + "\n"
			current_line = word + " "
		else:
			current_line += word + " "
	# Add any leftover
	if current_line.strip_edges() != "":
		result += current_line.strip_edges()
	return result

func Pop() -> void:
	#var PrevSize = TutorialPanel.size + Vector2(20,20)
	$PanelContainer/VBoxContainer.hide()
	
	TutorialPanel.scale = Vector2.ZERO
	#TutorialPanel.position = size / 2
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(TutorialPanel, "scale", Vector2(1,1), 0.75)
	#tw.set_parallel(true)
	#tw.tween_property(TutorialPanel, "position", (size / 2) - (PrevSize / 2), 0.75)
	tw.finished.connect($PanelContainer/VBoxContainer.show)
	


func _on_button_pressed() -> void:
	$PanelContainer/VBoxContainer.hide()
	
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUINT)
	tw.tween_property(TutorialPanel, "scale", Vector2.ZERO, 0.75)
	#tw.set_parallel(true)
	#tw.tween_property(TutorialPanel, "position", size / 2, 0.75)
	tw.finished.connect(Finished)

func Finished() -> void:
	Ended.emit()
	queue_free()
