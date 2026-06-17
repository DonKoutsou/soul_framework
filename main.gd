extends Node

class_name Main

@export var StartingLevel : Map.LocationName = Map.LocationName.Base

@export_group("File Paths")
@export_file() var StageScene : String

@export_file() var StartingMenuScene : String

@export_file() var ParticleScene : String


@export var PopM : PackedScene

var Menu : StartingMenu
var GameInstance : Stage
var EndCard : EndScreen

func _ready() -> void:
	Settings.LoadSettings()
	
	InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)
	
	var part = await Helper.Instance.LoadThreaded(ParticleScene).Finished
	var proloaderScene : AssetPreloader = part.instantiate()
	add_child(proloaderScene)
	
	Helper.Instance.FakeLoading(true, true, "Preloading assets")
	await proloaderScene.finished
	
	Helper.Instance.FakeLoading(false, true, "Preloading assets")
	Menu = load(StartingMenuScene).instantiate() as StartingMenu
	$SubViewportContainer/SubViewport.add_child(Menu)
	Menu.StartPressed.connect(StartGame)
	Menu.TestStartPressed.connect(StartTestMap)
	Menu.LoadPressed.connect(LoadGame)
	#Menu.SettingsPressed.connect(ToggleSettings)
	set_process_input(false)

func StartGame() -> void:
	Menu.PlayIntro()
	
	var StageSc = await Helper.Instance.LoadThreaded(StageScene).Finished
	GameInstance = StageSc.instantiate() as Stage
	
	await Menu.Hide()
	Menu.queue_free()

	$SubViewportContainer/SubViewport.add_child(GameInstance)
	GameInstance.StartingLevel = StartingLevel
	GameInstance.GameEnded.connect(GameWon)
	GameInstance.GameSaved.connect(SaveGame)
	GameInstance.GameClosed.connect(BackToMenu)
	#await GameInstance.LoadedLevels
	#await get_tree().create_timer(1).timeout
	
	set_process_input(true)

func LoadGame() -> void:
	var CurrentVersion = ProjectSettings.get_setting("application/config/version")
		
	if (!FileAccess.file_exists("user://SavedGame.tres")):
		var p = Menu.PopM.instantiate() as PopMenu
		Menu.add_child(p)
		p.Pop("No Savefile Found", false)
		return
	
	var sav = load("user://SavedGame.tres") as Save
	
	if (sav == null):
		var p = Menu.PopM.instantiate() as PopMenu
		Menu.add_child(p)
		p.Pop("Couldn't Load Save", false)
		return
	
	if (sav.GameVersion != CurrentVersion):
		var p = Menu.PopM.instantiate() as PopMenu
		Menu.add_child(p)
		p.Pop("Wrong Save Version", false)
		return
	
	Menu.PlayIntro()
		
	var StageSc = await Helper.Instance.LoadThreaded(StageScene).Finished
	GameInstance = StageSc.instantiate() as Stage
	
	await Menu.Hide()
	Menu.queue_free()

	$SubViewportContainer/SubViewport.add_child(GameInstance)
	GameInstance.GameEnded.connect(GameWon)
	GameInstance.GameSaved.connect(SaveGame)
	GameInstance.GameClosed.connect(BackToMenu)
	GameInstance.SaveToLoad = sav
	#await GameInstance.LoadedLevels
	await get_tree().create_timer(1).timeout
	
	set_process_input(true)

func StartTestMap() -> void:
	Menu.PlayIntro()
	var StageSc = await Helper.Instance.LoadThreaded(StageScene).Finished
	GameInstance = StageSc.instantiate() as Stage

	await Menu.Hide()
	Menu.queue_free()
	
	$SubViewportContainer/SubViewport.add_child(GameInstance)
	GameInstance.StartingLevel = Map.LocationName.Test_Map
	GameInstance.GameEnded.connect(GameWon)
	GameInstance.GameSaved.connect(SaveGame)
	GameInstance.GameClosed.connect(BackToMenu)
	#await GameInstance.LoadedLevels
	await get_tree().create_timer(1).timeout
	
	set_process_input(true)

func GameWon() -> void:
	get_tree().paused = true
	InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)
	SpawnStartMenu()

func SpawnStartMenu() -> void:
	Menu = load(StartingMenuScene).instantiate() as StartingMenu
	$SubViewportContainer/SubViewport.add_child(Menu)
	Menu.StartPressed.connect(StartGame)
	Menu.LoadPressed.connect(LoadGame)
	Menu.TestStartPressed.connect(StartTestMap)

func BackToMenu() -> void:
	get_tree().paused = false
	GameInstance.queue_free()
	SpawnStartMenu()
	set_process_input(false)

func SaveGame() -> void:
	var Data = GameInstance.GetSaveData()
	Data.GameVersion = ProjectSettings.get_setting("application/config/version")
	ResourceSaver.save(Data, "user://SavedGame.tres")
