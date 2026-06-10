extends CanvasLayer

class_name UIManager

@export_group("Data")
@export_file() var RestInterfaceFilePath : String
@export_file() var ShopFilePath : String
@export_file() var FireMenuFilePath : String
@export var CharacterSheetScene : PackedScene

@export var InventoryScene : PackedScene
@export var PauseM : PackedScene
@export var SettingsMenuScene : PackedScene
@export var CheatMenu : PackedScene

@export_group("Nodes")
@export var MiniMp : Minimap
@export var Inv : Inventory
@export var CharacterSheetPlecement : Control
@export var DiedLabel : Label
@export var Diag : DialogueBox
@export var MBox : MessageBox

static var MinimapOn : bool = false
static var InventoryOn : bool = false

#UI state booleans

static var PMenu : PauseMenu
static var SettingsM  : Settings

signal ItemUsed(It : Item)
signal AssistanceToggled(t : bool)
signal UIToggled(t : bool, AffectTime : bool)
signal CloseGame
signal SaveGame

var InFight : bool = false

func _ready() -> void:
	Inv = InventoryScene.instantiate()
	add_child(Inv)
	move_child(Inv, 0)
	Inv.ItemUsed.connect(OnItemUsed)
	Inv.AssistanceItem.connect(OnAssistanceToggled)
	Inv.RequestClose.connect(ToggleInventory)
	InputManager.Instance.PausePressed.connect(PausePressed)
	if (OS.is_debug_build()):
		var cheats = CheatMenu.instantiate()
		add_child(cheats)

func PausePressed() -> void:
	if (SettingsM != null):
		ToggleSettings()
	else: if (AnyUIOpen()):
		CloseAllUI()
	else : if (get_tree().paused):
		if (PMenu == null):
			return
		PMenu._on_resume_pressed()
	else:
		PMenu = PauseM.instantiate()
		add_child(PMenu)
		PMenu.Exit.connect(QuitGameRequest)
		PMenu.SaveRequested.connect(SaveGameRequest)
		PMenu.SettingsPressed.connect(ToggleSettings)


func Update(delta : float) -> void:
	MBox.Update(delta)

func OnUIToggled(AffectTime : bool = true) -> void:
	UIToggled.emit(AnyUIOpen(), AffectTime)

func Resume() -> void:
	PMenu.ResumePressed()

func QuitGameRequest() -> void:
	CloseGame.emit()

func SaveGameRequest() -> void:
	SaveGame.emit()

func ToggleSettings() -> void:
	if (SettingsM != null):
		SettingsM.SaveSettings()
		SettingsM.queue_free()
	else:
		SettingsM = SettingsMenuScene.instantiate()
		add_child(SettingsM)
		SettingsM.Close.connect(ToggleSettings)

func ToggleFight(t : bool) -> void:
	#StressBar.visible = !t
	if (t):
		MiniMp.visible = false
	else:
		MiniMp.visible = MiniMp.ShowMinimap
	#FagigueBar.visible = t
	InFight = t

func AddNewCharacter(Char : Character) -> void:
	for g in CharacterSheetPlecement.get_children():
		g.queue_free()
	
	var newSheet = CharacterSheetScene.instantiate() as CharacterSheet
	newSheet.SetCharacter(Char, 0)
	#var box = VBoxContainer.new()
	#box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#box.add_child(newSheet)
	#box.add_child(Control.new())
	CharacterSheetPlecement.add_child(newSheet)


func OnItemUsed(It : Item) -> void:
	ItemUsed.emit(It)

func OnAssistanceToggled(t : bool) -> void:
	AssistanceToggled.emit(t)

func ProcessInput(event: InputEvent) -> void:
	if (event.is_action_pressed("Map") and !InFight):
		ToggleMinimap()
	else : if (event.is_action_pressed("Inventory")):
		ToggleInventory()

func ToggleInventory() -> void:
	if (InventoryOn):
		Inv.ToggleInventoryUI(false)
		InventoryOn = false
	else:
		Inv.ToggleInventoryUI(true)
		InventoryOn = true
	OnUIToggled()

func ToggleMinimap() -> void:
	if (MinimapOn):
		MiniMp.ToggleMinimap(false)
		MinimapOn = false
	else:
		MiniMp.ToggleMinimap(true)
		MinimapOn = true
	OnUIToggled()

static func AnyUIOpen() -> bool:
	return MinimapOn or InventoryOn or TutorialManager.IsShowingTutorial




func CloseAllUI() -> void:
	if (InventoryOn):
		ToggleInventory()
	if (MinimapOn):
		ToggleMinimap()
		
	OnUIToggled()
