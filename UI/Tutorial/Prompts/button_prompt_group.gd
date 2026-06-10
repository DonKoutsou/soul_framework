extends TextureRect

class_name ButtonPromptGroup

var ChildAmmount : int = 0
var ToBePressed : int = 0

signal AllPressed

func ProcessInput(event : InputEvent) -> void:
	for g in get_children():
		g.ProcessInput(event)


func _ready() -> void:
	ChildAmmount = get_child_count()
	ToBePressed = ChildAmmount
	for g : ButtonPrompt in get_children():
		g.Finished.connect(PromptPushed)
	for g : ButtonPrompt in get_children():
		g.PromptPressed.connect(Pressed)

func Pressed() -> void:
	ToBePressed -= 1
	if (ToBePressed == 0):
		AllPressed.emit()

func PromptPushed() -> void:
	ChildAmmount -= 1
	
	if (ChildAmmount == 0):
		queue_free()
