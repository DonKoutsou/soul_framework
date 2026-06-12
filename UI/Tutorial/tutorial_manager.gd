extends Control

class_name  TutorialManager

@export_group("Data")
@export var Tutorials : Dictionary[TutorialTypes, TutorialData]
@export var Prompt : PackedScene
@export var TutorialPrompt : PackedScene
@export_group("Nodes")
@export var fight : FightScene

var DoneTutorials : Array[TutorialTypes]

signal TutorialPresented
signal TutorialFinished

var EvadeTutorialAmmount : int = 0

static var ShowTutorial : bool = false

static var IsShowingTutorial : bool = false
static var Instance : TutorialManager

var GrabIndicator : ButtonPrompt

enum TutorialTypes{
	LANTERN,
	FIGHT,
	FIRE_PIT,
	REST,
	DRAG,
	SHOVEL,
	LIGHT_DOOR,
	LOCKED_DOOR,
}

func _ready() -> void:
	Instance = self
	if(ShowTutorial):
		fight.GetPlayer().AtackAvoided.connect(InitialRevenge)
	else:
		for g in get_children():
			g.queue_free()

func ProcessInput(event : InputEvent) -> void:
	for g in get_children():
		if (g is ButtonPrompt or g is ButtonPromptGroup):
			g.ProcessInput(event)

func PlayTextInstruction(Type : TutorialTypes) -> void:
	if (DoneTutorials.has(Type) or !ShowTutorial):
		return
	if (!Tutorials.has(Type)):
		printerr("Missing tutorial for {0}".format([TutorialTypes.keys()[Type]]))
		return
	InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)
	DoneTutorials.append(Type)
	WorldTimeManager.Instance.StopTime()
	TutorialPresented.emit()
	
	var Tut = Tutorials[Type]
	var TutorialP = TutorialPrompt.instantiate() as TutorialTextPrompt
	TutorialP.SetTexts(Tut.TutorialTitle, Tut.TutorialText)
	add_child(TutorialP)
	TutorialP.Ended.connect(TextTutorialEnded)
	IsShowingTutorial = true

func TextTutorialEnded() -> void:
	InputManager.ChangeMouse(Input.MOUSE_MODE_CAPTURED)
	WorldTimeManager.Instance.StartTime()
	TutorialFinished.emit()
	IsShowingTutorial = false

func IndicateGrab(t : bool) -> void:
	if (GrabIndicator != null):
		GrabIndicator.queue_free()
	if (t):
		GrabIndicator = Prompt.instantiate() as ButtonPrompt
		GrabIndicator.Tooltip = "Hold"
		GrabIndicator.InputName = "AtackRight"
		#GrabIndicator.AllPressed.connect(Resume)
		add_child(GrabIndicator)

func InitialAtack(Direction : FightCharacter.AtackSide) -> void:
	
	EvadeTutorialAmmount += 1
	if (EvadeTutorialAmmount >= 10):
		fight.GetEnemy().AtackStarted.disconnect(InitialAtack)
		return
	else : if (EvadeTutorialAmmount > 5):
		await get_tree().create_timer(0.1).timeout
		var b = Prompt.instantiate() as ButtonPrompt
		b.Tooltip = "Hold"
		b.InputName = "AtackRight"
		b.PromptPressed.connect(Resume)
		add_child(b)
	else:
		await get_tree().create_timer(0.1).timeout
		var b = Prompt.instantiate() as ButtonPrompt
		if (Direction == FightCharacter.AtackSide.RIGHT):
			b.InputName = "DuckLeft"
			#b.KeyIcon = "Q"
		else: if (Direction == FightCharacter.AtackSide.LEFT):
			b.InputName = "DuckRight"
			#b.KeyIcon = "E"
		else: if (Direction == FightCharacter.AtackSide.MIDDLE):
			b.InputName = "DuckRight"
			
		else: if (Direction == FightCharacter.AtackSide.TOP):
			b.InputName = "DuckRight"
		else: if (Direction == FightCharacter.AtackSide.LOW):
			b.InputName = "DuckLeft"
		b.Tooltip = "Hold"
			#b.KeyIcon = "E"
		b.PromptPressed.connect(Resume)
		add_child(b)

	WorldTimeManager.Instance.StopTime(0.5)
	TutorialPresented.emit()

func InitialRevenge() -> void:
	await get_tree().create_timer(0.2).timeout
	var b = Prompt.instantiate() as ButtonPrompt
	b.InputName = "AtackLeft"
	b.Tooltip = "Press"
	b.PromptPressed.connect(Resume)
	add_child(b)
	WorldTimeManager.Instance.StopTime(0.5)
	TutorialPresented.emit()
	if (EvadeTutorialAmmount >= 5):
		fight.GetPlayer().AtackAvoided.disconnect(InitialRevenge)

func Resume() -> void:
	WorldTimeManager.Instance.StartTime()
	TutorialFinished.emit()
