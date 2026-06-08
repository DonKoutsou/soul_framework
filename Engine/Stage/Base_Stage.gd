#Stage is the Root node of the playable world.
#
@tool
extends Node

class_name Stage

#----------------------------------------------------------------

@export_group("Start Settings")
@export var StartingCharacter : Character
@export_file_path() var StartingItems : Array[String]
@export var StartingLevel : Map.LocationName = Map.LocationName.Base

#----------------------------------------------------------------

@export_group("Data")
@export_file("*.tscn") var PlayerControllerFilePath : String
@export_file("*.tscn") var LockPuzzleFilePath : String
@export_file("*.tscn") var FightPackedScene : String
@export_file("*.tscn") var UIManagerFilePath : String
@export_file("*.tscn") var DeathParticles : String

@export_file("*.tscn") var LightPartScene : String
@export_file("*.tscn") var chest_animation: String
@export_file("*.tscn") var Item_animation: String
@export var MapStoreDirs : Array[String]
#----------------------------------------------------------------

@export_group("Nodes")
@export var DungeonL : DungeonLabel
@export var StreesVignette : ShaderMaterial
@export var Node_Spawn_Loc : Node

var DialogueMan : DialogueManager

var Rewards : Array[Node3D]
#----------------------------------------------------------------

var SaveToLoad : Save

#----------------------------------------------------------------

var UIMan : UIManager
var Fight : FightScene



var playerCharacter : Character

#Stored worlds gets filled with the generated data at start of game.
#This data is stored on save file.
static var CurrentWorld : Level
static var StoredWorlds : Dictionary[Map.LocationName, MapData]



#Stored location, player will return here upon death
var PlayerLastRestLocation : Vector3i
var PlayerLastRestDirection : float

#PlayerController
static var Manequin : BasePlayerManequin

static var TransitioningLevel : bool = false

#signal LoadedLevels
signal GameEnded
signal GameSaved
signal GameClosed

var Dead : bool = false

var TransitionTween : Tween

static var CurrentFreeCam : Freecam
#----------------------------------------------------------------
const FreecamScene : String = "res://Engine/Debug/freecam.tscn"

static var Isntance : Stage

static func ToggleFreecam() -> void:
	if (CurrentFreeCam == null):
		CurrentFreeCam = load(FreecamScene).instantiate()
		CurrentWorld.add_child(CurrentFreeCam)
		CurrentFreeCam.global_position = Manequin.position
	else:
		CurrentFreeCam.queue_free()
		CurrentFreeCam = null

func _ready() -> void:
	
	if (Engine.is_editor_hint()):
		return
	StreesVignette.set_shader_parameter("outerRadius", 2.0)
	Isntance = self

	SpawnUI()
	SpawnFight()
	#call_deferred("SpawnFight")
	
	DialogueMan = DialogueManager.Create(UIMan.Inv)
	Node_Spawn_Loc.add_child(DialogueMan)
	DialogueMan.RecruitTeleportRequest.connect(RecruitTeleport)
	#SpawnFight()

	set_process(false)
	set_process_input(false)
	Helper.Instance.FakeLoading(true, true, "Preloading Levels")
	#call_deferred("LoadLevels")
	if (SaveToLoad == null):
		NewGame()
	else:
		LoadGame(SaveToLoad)

func SpawnUI() -> void:
	print("Spawning UI Manager")
	var UIManPackedScene = load(UIManagerFilePath) as PackedScene
	UIMan = UIManPackedScene.instantiate()
	Node_Spawn_Loc.add_child(UIMan)
	UIMan.ItemUsed.connect(EV_ItemUsed)
	UIMan.AssistanceToggled.connect(AssistanceToggled)
	UIMan.UIToggled.connect(UIToggled)
	UIMan.Inv.ItemAdded.connect(EV_OnItemAdded)
	UIMan.CloseGame.connect(CloseGame)
	UISoundMan.GetInstance().Refresh()
	
func CloseGame() -> void:
	GameClosed.emit()

func SpawnFight() -> void:
	print("Spawning First Person Scene")
	var FightPack = load(FightPackedScene) as PackedScene
	Fight = FightPack.instantiate()
	Node_Spawn_Loc.add_child(Fight)

	Fight.EnemyKilled.connect(EV_MonsterKilled)
	
	Fight.FightStared.connect(UIMan.ToggleFight.bind(true))
	Fight.FightEnded.connect(UIMan.ToggleFight.bind(false))
	
	Fight.Effect.connect(UIMan.Inv.ApplyEffects)
	Fight.EnviromentalAttack.connect(AtackEnviroment)

	Fight.TutorialToggled.connect(UIToggled)

func _input(event: InputEvent) -> void:
	if (CurrentFreeCam != null):
		CurrentFreeCam.ProcessInput(event)
		return
		
	if (Dead):
		return
		
	if (DialogueMan.InDialogue):
		return
	
	if (Fight.GetPlayer().Digging):
		return
	
	UIMan.ProcessInput(event)
	
	if (UIManager.AnyUIOpen()):
		return
	
	Fight.ProcessInput(event)
	if (Fight.IsInFight()):
		return
	
	Manequin.ProcessInput(event)
	

func _process(delta: float) -> void:
	if (Engine.is_editor_hint()):
		return
	var FinalDelta = delta * WorldTimeManager.GameFrameTimeMulti
	
	if (CurrentFreeCam != null):
		CurrentWorld.Update(FinalDelta)
		return
	
	UIMan.Update(delta)
	Fight.Update(FinalDelta)
	Manequin.ProcessTweens(FinalDelta)
	
	if (!Fight.GetPlayer().PulledWeapon):
		for g in Rewards:
			g.Update(delta)
	
	if (Fight.IsInFight()):
		return
	
	CurrentWorld.Update(FinalDelta)
	
	if (Dead):
		return
	
	if (DialogueMan.InDialogue):
		return
	
	Manequin.Update(FinalDelta)
	
	if (Fight.GetPlayer().Digging):
		return

func _exit_tree() -> void:
	if (CurrentWorld != null):
		CurrentWorld.queue_free()
	StoredWorlds.clear()
	BasePlayerManequin.CanWalkOnLava = false
	BasePlayerManequin.CanWalkOnWater = false
	BasePlayerManequin.CanWalkOverGaps = false
#----------------------------------------------------------------

#USed to change the current playable level, pass in data that was stored to not regenerate world
func switch_levels(NewLevel : Level, SavedData : MapData = null) -> void:
	
	#Add a loading screen
	Helper.Instance.FakeLoading(true, true)
	set_process(false)
	set_process_input(false)
	
	var LastLevelName = -1
	
	if (CurrentWorld != null):
		#If we are in a world now we need to store the data
		UIMan.MiniMp.StoreCurrentWorldData(CurrentWorld.MData.LevelName)
		LastLevelName = CurrentWorld.MData.LevelName
		StoredWorlds[LastLevelName] = CurrentWorld.GetMapData()
		CurrentWorld.queue_free()
		Rewards.clear()
	
	#Add new world to tree
	Node_Spawn_Loc.add_child(NewLevel)
	
	#Spawn the map that the saved data belongs too and restore the data to it
	var MapScene = load(SavedData.MapDir) as PackedScene
	var RestoredMap = MapScene.instantiate()
	NewLevel.configure_map(RestoredMap)

	
	NewLevel.MData.Data = SavedData

	#If we are comming from another level 
	#we find the connecting doors and set them as spawnpoint
	if (LastLevelName != -1):
		assert(NewLevel.GetMapData().Doors.values().has(LastLevelName), "Conection of levels could not be foud, sounds sus.")
		
		#Itterate through the doors of the new level to find the door that connects us to the last one
		for DoorLocation in NewLevel.GetMapData().Doors:
			var ConnectedLevelName = NewLevel.GetMapData().Doors[DoorLocation]
			if (ConnectedLevelName == LastLevelName):
				
				#Once we find the door set the new spawn point location
				NewLevel.GetMapData().SpawnPoint = DoorLocation
				
				#We need to figure out the direction the player should face when comming into the new level
				var ExitLocation = Vector3(NewLevel.GetMapData().Exits.find_key(ConnectedLevelName))
				
				#After finding the exit location we get the direction away from it
				var Dir = Vector2(DoorLocation.x, DoorLocation.z).direction_to(Vector2(ExitLocation.x, ExitLocation.z))
				var yaw_angle = atan2(Dir.x, Dir.y)
				
				#Set the wanted rotation and break out of the loop
				NewLevel.GetMapData().SpawnRot = yaw_angle
				break
	
	CurrentWorld = NewLevel
	CurrentWorld.EnemyMet.connect(Fight.EnemyMet)
	CurrentWorld.ProjectileSwitchPressed.connect(HandleProjectileSwitch)
	DialogueMan.CurrentWorldChanged(NewLevel)
	#Set new respawn location
	PlayerLastRestLocation = CurrentWorld.GetMapData().SpawnPoint
	
	#Update minimap
	UIMan.MiniMp.LoadWorldData(CurrentWorld.MData.LevelName)
	
	#Start setting up the geometry and collisions
	NewLevel.StartBuildingThread()
	NewLevel.GenerationFinished.connect(GenerationFinished)
	
func GenerationFinished() -> void:
	CurrentWorld.GenerationFinished.disconnect(GenerationFinished)
	#Turn of the loading screen
	Helper.Instance.FakeLoading(false)
	
	#Spawn player controller
	SpawnPlayer()
	set_process(true)
	set_process_input(true)
	
	#Location name UI
	DungeonL.ShowLocation(CurrentWorld.MData.LevelName)

func SpawnPlayer() -> void:
	var PlayerControllerScene = load(PlayerControllerFilePath) as PackedScene
	Manequin = PlayerControllerScene.instantiate() as BasePlayerManequin
	
	Manequin.PositionChanged.connect(PlayerPositionChanged)
	Manequin.HitWall.connect(WallHit)
	Manequin.OrientationChanged.connect(PlayerOrientationChanged)
	
	Manequin.NPC_MET.connect(DialogueMan.NPC_MET)
	Manequin.LockedDoorMet.connect(FoundDoor)
	Manequin.PlayerFighter = Fight.GetPlayer()
	Manequin.VerticalMovement.connect(VerticalMovement)
	Manequin.Teleported.connect(Teleported)
	Manequin.DialogueMet.connect(DialogueMet)
	Manequin.MovableFound.connect(EV_MovableFound)
	Manequin.MovableLifted.connect(MovableLifted)
	Manequin.RegisterPlayerCharacter(playerCharacter)
	
	
	Fight.FightStared.connect(Manequin.FightToggled.bind(true))
	Fight.FightEnded.connect(Manequin.FightToggled.bind(false))
	Fight.GetPlayer().CharacterDucked.connect(Manequin.Duck)
	Fight.GetPlayer().CharacterUnducked.connect(Manequin.UnDuck)
	
	DialogueMan.ManequinSpawned(Manequin)
	
	CurrentWorld.SpawnPlayer(Manequin)

func UIToggled(t : bool, AffectTime : bool) -> void:
	if (t):
		if (AffectTime):
			WorldTimeManager.Instance.StopTime()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if (AffectTime):
			WorldTimeManager.Instance.StartTime()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
	Manequin.CanMove = !t


	
#----------------------------------------------------------------

func DialogueMet(Pos : Vector3i, Dialogues : DialogueContainer) -> void:
	if (Dialogues.Dialogues.size() == 0):
		return
	UIMan.Diag.DoDialogue(Dialogues)
	CurrentWorld.GetMapData().Texts.erase(Helper.PlayerPositionToMap(Pos))
	
	
func AssistanceToggled(t : bool) -> void:
	Fight.AtackIndicatorUI.ToggleHelp(t)
	
	



func RecruitTeleport(mapCharacter : MapCharacter, NewLocation : Map.LocationName, Pos : Vector3i) -> void:
	var loc = StoredWorlds[NewLocation]
	
	var cell = loc.GetCell(Pos) 
	cell.AddData("Recruit", mapCharacter)
	
	var CurrentLoc = Helper.PlayerPositionToMap(mapCharacter.position)
	var currentCell = loc.GetCell(CurrentLoc)
	currentCell.Custom_Data.erase("Recruit")


#func FoundMerchant() -> void:
	#Manequin.ReturnCam()
	#Stranger.OverrideLook = false
	#UIMan.SpawnShopUI()


func RegisteCharachter(Char : Character) -> void:
	playerCharacter = Char
	
	Char.OnDeath.connect(EV_CharacterDeath.bind(Char))
	Char.Killed.connect(EV_CharacterKilled.bind(Char))
	
	Char.Init()
	UIMan.AddNewCharacter(Char)
	
	
	Fight.RegisterPlayerCharacter(playerCharacter)
	UIMan.Inv.ChangeWeapon(playerCharacter.CharacterWeapon)


func Dig(Pos : Vector3i) -> void:
	
	var cell = CurrentWorld.GetMapData().cells[Pos]
	
	if (cell.type == CellData.CELLTYPE.DUG_DUGGABLE):
		MessageBox.RegisterEvent("Already dug here")
		return
	if (cell.type == CellData.CELLTYPE.DUGGABLE):
		Fight.GetPlayer().Dig()
		Fight.GetPlayer().DigComplete.connect(DigComplete.bind(Pos))
		Manequin.CanMove = false
		Manequin.ReturnCam(0.5)
		UIMan.ToggleInventory()
		
	else:
		MessageBox.RegisterEvent("Can't dig here")

func DigComplete(Pos : Vector3i) -> void:
	Fight.GetPlayer().DigComplete.disconnect(DigComplete.bind(Pos))
	
	var cell = CurrentWorld.GetMapData().cells[Pos]
	if (cell.HasData("Item")):
		var It = load(cell.Custom_Data["Item"])
		cell.Custom_Data.erase("Item")

		MessageBox.RegisterEvent("You dug out an item")
		UIMan.Inv.AddItem(It)
		var chAnim =  load(Item_animation).instantiate() as ChestAnimation
		Node_Spawn_Loc.add_child(chAnim)
		chAnim.Init(It)
	else:
		MessageBox.RegisterEvent("Found nothing...")
	CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.DUGGABLES, [Pos])
	cell.type = CellData.CELLTYPE.DUG_DUGGABLE
	
	Manequin.CanMove = true
	
	CurrentWorld.QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.DUG_DUGGABLES)
	CurrentWorld.QueuedUpdate = true

	
#----------------------------------------------------------------
#Player moving events

func PlayerOrientationChanged(PlayerPosition : Vector3, PlayerOrientation : float) -> void:
	var Pos = Helper.PlayerPositionToMap(Vector3i(PlayerPosition))
	UIMan.MiniMp.OnPositionVisited(Pos, PlayerOrientation)
	CurrentWorld.MonsterMan.TakeAction()
	CurrentWorld.PlayerPositionChanged(PlayerPosition, Vector3.FORWARD.rotated(Vector3(0,1,0), PlayerOrientation))

func PlayerPositionChanged(OriginalPlayerPosition : Vector3, NewPlayerPosition : Vector3, PlayerOrientation : float, Moved : bool = true) -> void:
	#if (Moved):
	CurrentWorld.MonsterMan.TakeAction()
	
	var Pos = Helper.PlayerPositionToMap(NewPlayerPosition)
	var OriginalPos = Helper.PlayerPositionToMap(OriginalPlayerPosition)
	
	var cell = CurrentWorld.GetMapData().cells[Pos]
	print("Player moved to location : {0}".format([Pos]))
	
	if (cell.type == CellData.CELLTYPE.ENDPOINT):
		GameEnded.emit()
		return

	#UPDATE MINIMAP POSITIONS
	var VisiblePositions = CurrentWorld.MData.GetVisible(Pos)
	
	
	UIMan.MiniMp.OnPositionVisited(Pos, PlayerOrientation)
	
	for g in VisiblePositions:
		UIMan.MiniMp.OnPositionSeen(Vector3i(g.x, Pos.y, g.y))
	#UPDATE STRESS LEVEL
	
	
	
	
	#CHECK IF A PLATE IS STEPPED ON AND OPEN THE GATE
	#if (CurrentWorld.GetMapData().Plates.has(OriginalPos) and Pos != OriginalPos):
		#MessageBox.RegisterEvent("A plate was released and a door has closed.")
		#var Data = CurrentWorld.GetMapData().Plates[OriginalPos]
		#Data.State = false
		#var Info = Data.Info
		#if (Info is DoorPreassurePlateCallInfo):
			#PlateCloseDoor(Info)
		#if (Info is GlobalSwitchCallInfo):
			#Info.SetGlobals(false)
		#AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
	
	#
	
	if (Manequin.HoldingPosition != Vector3i.ZERO and Pos != OriginalPos):
		if (!cell.Custom_Data.has("Movable")):
			var newpos = CurrentWorld.MultiMeshes[LevelMultimesh.LevelMultimeshTypes.MOVABLES].MoveMovable(CurrentWorld.GetMapData(), OriginalPos,Manequin.HoldingPosition, false)
			Manequin.HoldingPosition = newpos
		else:
			var newpos = CurrentWorld.MultiMeshes[LevelMultimesh.LevelMultimeshTypes.MOVABLES].MoveMovable(CurrentWorld.GetMapData() ,OriginalPos, Pos)
			Manequin.HoldingPosition = newpos
	
	#FALL TRAP
	if (Moved and cell.CrackedFloor):
		Manequin.FallStarted.connect(BreakFloor.bind(Pos))
		Manequin.FallDown = true
	
	#ITEM PICKUP
	else : if (cell.HasData("Item") and cell.type != CellData.CELLTYPE.DUGGABLE):
		#if (UIMan.Inv.HasSpace()):
		#Hand visual
		Fight.GetPlayer().ExtendHand()
		
		#Retrieve Item and Remove from world data
		var it = load(cell.Custom_Data["Item"])
		cell.Custom_Data.erase("Item")
		UIMan.Inv.AddItem(it)
		
		#Spawn pickup visuals
		var d = load(DeathParticles).instantiate() as GPUParticles3D
		CurrentWorld.add_child(d)
		d.global_position = Manequin.global_position + Vector3(0,0.3,0)
		d.emitting = true
		d.finished.connect(d.queue_free)
		AudioManager.Instance.PlaySound(AudioManager.Sound.MAGIC, -15, 0.1, 0.8, true)

		#Update Level Geometry
		CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.ITEMS, [Pos])
		
		var chAnim =  load(Item_animation).instantiate() as ChestAnimation
		Node_Spawn_Loc.add_child(chAnim)
		chAnim.Init(it)
	#if (CurrentWorld.GetMapData().Plates.has(Pos) and Pos != OriginalPos):
		#MessageBox.RegisterEvent("A plate was pressed and a door has opened.")
		#var Data = CurrentWorld.GetMapData().Plates[Pos]
		#Data.State = true
		#var Info = Data.Info
		#if (Info is DoorPreassurePlateCallInfo):
			#PlateOpenDoor(Info)
		#if (Info is GlobalSwitchCallInfo):
			#Info.SetGlobals(true)
		#AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
		#Manequin.Walkback = true
	#LIGHT DOOR
	
	
	
	
	#LEVEL TRANSITION
	if (CurrentWorld.GetMapData().Exits.has(Pos)):
		#var LoadingStored : bool = false
		var W = CurrentWorld.GetMapData().Exits[Pos]
		
		var StoredData : MapData = StoredWorlds[W]
		var WorldToSpawn : Level = load(StoredData.level).instantiate()

		if (Manequin.WalkDown or Manequin.WalkUp):
			#LevelTransition(WorldToSpawn, StoredData, 1.5)
			Manequin.VerticalMovementStarted.connect(LevelTransition.bind(WorldToSpawn, StoredData, 0.5))
		else: if (Manequin.FallDown):
			Manequin.FallStarted.connect(LevelTransition.bind(WorldToSpawn, StoredData, 1))
			#LevelTransition(WorldToSpawn, StoredData, 1)
		else:
			LevelTransition(WorldToSpawn, StoredData)
	
	#UPDATE AUDIO MANAGER
	CurrentWorld.AudioMan.PlayerLocationChanged(Pos)
	CurrentWorld.PlayerPositionChanged(NewPlayerPosition, Vector3.FORWARD.rotated(Vector3(0,1,0), PlayerOrientation))

func MovableLifted(t : bool) -> void:
	var cell = CurrentWorld.GetMapData().cells[Manequin.HoldingPosition]
	
	CurrentWorld.MultiMeshes[LevelMultimesh.LevelMultimeshTypes.MOVABLES].LiftMovable(CurrentWorld.GetMapData() ,Manequin.HoldingPosition, t)
	var MoveData : MovableData = cell.Custom_Data["Movable"]
	if (cell.HasData("Plate")):
		var PlateData = cell.Custom_Data["Plate"]
		if (PlateData.Info.Element == MoveData.Info.Element):
			PlateData.State = !t
			MoveData.State = !t
			if (t):
				MessageBox.RegisterEvent("A plate was released and a door has closed.")
				var Info = PlateData.Info
				if (Info is DoorPreassurePlateCallInfo):
					CloseDoor(Info.DoorLoc)
					CurrentWorld.UpdatePlate(Manequin.HoldingPosition)
					CurrentWorld.UpdateMovable(Manequin.HoldingPosition)
					
				else: if (Info is BridgePreassurePlateCallInfo):
					DissableBridge(Info.FloorPos)
					CurrentWorld.UpdatePlate(Manequin.HoldingPosition)
					CurrentWorld.UpdateMovable(Manequin.HoldingPosition)
					
				else: if (Info is GlobalSwitchCallInfo):
					Info.SetGlobals(false)
			else:
				MessageBox.RegisterEvent("A plate was pressed and a door has opened.")
				var Info = PlateData.Info
				if (Info is DoorPreassurePlateCallInfo):
					OpenDoor(Info.DoorLoc)
					CurrentWorld.UpdatePlate(Manequin.HoldingPosition)
					CurrentWorld.UpdateMovable(Manequin.HoldingPosition)
					
				else: if (Info is BridgePreassurePlateCallInfo):
					EnableBridge(Info.FloorPos)
					CurrentWorld.UpdatePlate(Manequin.HoldingPosition)
					CurrentWorld.UpdateMovable(Manequin.HoldingPosition)
					
				else: if (Info is GlobalSwitchCallInfo):
					Info.SetGlobals(true)

func LevelTransition(NewWorld : Level, SavedData : MapData = null, TransitionTime : float = 0.5) -> void:
	
	TransitioningLevel = true
	Manequin.CanMove = false
	if (is_instance_valid(TransitionTween)):
		TransitionTween.kill()
	TransitionTween = get_tree().create_tween()
	TransitionTween.tween_property(StreesVignette, "shader_parameter/outerRadius", 0.0, TransitionTime)
	TransitionTween.finished.connect(LevelTransitionFinished)
	TransitionTween.finished.connect(switch_levels.bind(NewWorld, SavedData))
	
func LevelTransitionFinished() -> void:
	Manequin.CanMove = true
	if (is_instance_valid(TransitionTween)):
		TransitionTween.kill()
	TransitionTween = get_tree().create_tween()
	TransitionTween.tween_property(StreesVignette, "shader_parameter/outerRadius", 2, 1)
	TransitionTween.finished.connect(set.bind("TransitioningLevel", false))
	#TransitionTween.finished.connect(set.bind("Dead", false))
#	TransitioningLevel = false
	Dead = false

func VerticalMovement(t : bool, Up : bool) -> void:
	if (t):
		if (is_instance_valid(TransitionTween)):
			TransitionTween.kill()
		TransitionTween = get_tree().create_tween()
		TransitionTween.tween_property(StreesVignette, "shader_parameter/outerRadius", 0.0, 0.3)
		Dead = true
	if (!t):
		if (is_instance_valid(TransitionTween)):
			TransitionTween.kill()
		TransitionTween = get_tree().create_tween()
		TransitionTween.tween_property(StreesVignette, "shader_parameter/outerRadius", 2, 0.3)
		TransitionTween.finished.connect(set.bind("Dead", false))
		
		get_tree().call_group("Enviroments", "ElevationChanged", Up)

func Teleported(Height : float) -> void:
	get_tree().call_group("Enviroments", "SetElevation", Height)
	#$CanvasLayer/SubViewportContainer/SubViewport.SetElevation(Height)

#Called from signal in Manequin when collision with door happens
func FoundDoor(Pos : Vector3i) -> void:
	
	Fight.GetPlayer().ExtendHand()
	var cell = CurrentWorld.GetMapData().cells[Pos]
	
	if (cell.HasData("LightDoor")):
		MessageBox.RegisterEvent("Way is blocked by a protective veil")
		return
	
	var DoorDat : DoorData = cell.Custom_Data["Door"]
	#Check if locked
	if (cell.HasData("Locks")):
		MessageBox.RegisterEvent("Door is locked...")
		AudioManager.Instance.PlaySound(AudioManager.Sound.LOCK_STUCK, -5, 0, 1, false)
		
	#Check for master lock (special key)
	else : if (cell.HasData("MasterLocks")):
		
		#check if master key in inventory
		if (UIMan.Inv.HasKeyItem(KeyItem.KeyItemType.MASTER_KEY)):
			var OppositeDoorMapPos : Vector3i = CurrentWorld.GetMapData().DoorList[Pos].OpossiteDoorMapPosition
			CurrentWorld.ToggleDoor(Pos)
			CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.LOCKS, [Pos, OppositeDoorMapPos])
			CurrentWorld.UpdateDoors()
			UIMan.MiniMp.OnDoorUnlocked(Pos)
			UIMan.MiniMp.OnDoorUnlocked(OppositeDoorMapPos)
			AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
			MessageBox.RegisterEvent("Door unlocked")
			UIMan.Inv.RemoveKeyItem(KeyItem.KeyItemType.MASTER_KEY)
		else: if (UIMan.Inv.HasKeyItem(KeyItem.KeyItemType.CHEST_KEY)):
			MessageBox.RegisterEvent("Normal keys wont work here...")
			AudioManager.Instance.PlaySound(AudioManager.Sound.LOCK_STUCK, -5, 0, 1, false)
		else:
			MessageBox.RegisterEvent("Impossible to unlock door...")
			AudioManager.Instance.PlaySound(AudioManager.Sound.LOCK_STUCK, -5, 0, 1, false)
	
	
	#Check if blocked
	else : if (DoorDat.Blocked):
		var OppositeDoorMapPos = DoorDat.OpossiteDoorMapPosition
		var oppositeCell = CurrentWorld.GetMapData().cells[OppositeDoorMapPos]
		if (!oppositeCell.HasData("Door")):
			MessageBox.RegisterEvent("Door blocked from this side.")
			return
		var oppositeDoor : DoorData = oppositeCell.Custom_Data["Door"]
		if (oppositeDoor.Blocked):
			MessageBox.RegisterEvent("Door is locked by a contraption...")
		else:
			MessageBox.RegisterEvent("Door blocked from this side.")
			
		AudioManager.Instance.PlaySound(AudioManager.Sound.LOCK_STUCK, -5, 0, 1, false)
	
	else: if (!DoorDat.Locked):
		var OppositeDoorMapPos = DoorDat.OpossiteDoorMapPosition
		CurrentWorld.ToggleDoor(Pos)
		
		DoorDat.Blocked = false
		UIMan.MiniMp.OnBlockOpened(OppositeDoorMapPos)
		MessageBox.RegisterEvent("Door opened")
		AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)

func WallHit(PlayerPosition : Vector3, PlayerOrientation : float) -> void:
	var Pos = Helper.PlayerPositionToMap(Vector3i(PlayerPosition))
	var cell = CurrentWorld.GetMapData().GetCell(Pos)
	
	if (cell.Custom_Data.has("Lever")):
		if (HandleLever(Pos, PlayerPosition, PlayerOrientation)):
			return

	MessageBox.RegisterEvent("Way is blocked", false)

func HandleProjectileSwitch(SwitchData : ProjectileSwitchData, Element : ProjectileSwitchData.SwitchElement, PlayerSpanwned : bool) -> void:
	var Info = SwitchData.Info
	if (Info.Element != Element):
		return
		
	SwitchData.State = !SwitchData.State
	
	if (!SwitchData.State):
		if (Info is DoorProjectileSwitchCallInfo):
			if (PlayerSpanwned):
				MessageBox.RegisterEvent("A switch was toggled and a door closed somewhere")
			CloseDoor(Info.DoorLoc)
		else : if (Info is BridgeProjectileSwitchCallInfo):
			if (PlayerSpanwned):
				MessageBox.RegisterEvent("A switch was toggled and a bridge closed somewhere")
			DissableBridge(Info.FloorPos)
	else:
		if (Info is DoorProjectileSwitchCallInfo):
			if (PlayerSpanwned):
				MessageBox.RegisterEvent("A switch was toggled a door opened somewhere")
			OpenDoor(Info.DoorLoc)
		else : if (Info is BridgeProjectileSwitchCallInfo):
			if (PlayerSpanwned):
				MessageBox.RegisterEvent("A switch was toggled and a bridge opened somewhere")
			EnableBridge(Info.FloorPos)
	
	CurrentWorld.UpdateProjectileSwitch(SwitchData.Pos)
	#CurrentWorld.QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.PROJECT_SWITCHES)
	#CurrentWorld.QueuedUpdate = true

func HandleLever(Pos : Vector3i, PlayerPosition : Vector3, PlayerOrientation : float) -> bool:
	var cell = CurrentWorld.GetMapData().GetCell(Pos)
	var LData = cell.Custom_Data["Lever"]
	var Info : LeverCallInfo = LData.Info
	if (Info.IsMissingPart):
		if (UIMan.Inv.HasItem(Info.MissingPart)):
			pass
			#UIMan.Inv.RemoveItem(Info.MissingPart)
			#Info.IsMissingPart = false
			#CurrentWorld.UpdateLevers(false)
			#MessageBox.RegisterEvent("The lever has been repaired")
			#AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
			#Fight.GetPlayer().ExtendHand()
		else:
			MessageBox.RegisterEvent("Lever is unfunctional, it's missing a piece.")
		return true
		
	var pos = Vector2(roundi((Pos.x)), roundi((Pos.z)))
	var Height = PlayerPosition.y / Level.CurrentWorldScale.y
	
	var WrapedOrientation = snappedf(wrapf(PlayerOrientation, -PI, PI), 0.0001)
	var WeappedTileRotation = wrapf(deg_to_rad(CurrentWorld.MData.GetTileRotationDegrees(pos, roundi(Height), FloorLayer.LayerType.LEVERS)) + (PI / 2), -PI, PI)
	
	if (!is_equal_approx(WrapedOrientation, WeappedTileRotation)):
		return false
		
	Fight.GetPlayer().ExtendHand()

	if (LData.State):
		MessageBox.RegisterEvent("Pulled a level and a door closed somewhere")
		LData.State = false
		
		if (Info is DoorLeverCallInfo):
			CloseDoor(Info.DoorLoc)
		else: if (Info is BridgeLeverCallInfo):
			DissableBridge(Info.FloorPos)
		else: if (Info is GlobalLeverCallInfo):
			Info.SetGlobals(true)
	else:
		MessageBox.RegisterEvent("Pulled a level and a door opened somewhere")
		LData.State = true
		if (Info is DoorLeverCallInfo):
			OpenDoor(Info.DoorLoc)
		else: if (Info is BridgeLeverCallInfo):
			EnableBridge(Info.FloorPos)
		else: if (Info is GlobalLeverCallInfo):
			Info.SetGlobals(false)
		
	CurrentWorld.FlipSwitch(Pos)
	#CurrentWorld.UpdateLevers()

	#AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
	return true
	
	
func EnableBridge(FloorPos : Array[Vector3i]):
	CurrentWorld.AddTo(LevelMultimesh.LevelMultimeshTypes.FLOOR, FloorPos)
	
	for g in FloorPos:
		AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.UNLOCK, g * CurrentWorld.CurrentWorldScale, -5, 0.2, 1, true, 5)
		CurrentWorld.RemoveHazard(g)

	AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5, 0.2, 1.5)
	
func DissableBridge(FloorPos : Array[Vector3i]) -> void:
	for florPos : Vector3i in FloorPos:
		var cell : CellData = CurrentWorld.GetMapData().GetCell(florPos)
		cell.spawnFloor = false
		
		AudioManager.Instance.PlaySoundLocational(AudioManager.Sound.UNLOCK, florPos * CurrentWorld.CurrentWorldScale, -5, 0.2, 1, true, 5)
		CurrentWorld.AddHazard(florPos)
	
	CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.FLOOR, FloorPos)
	AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5, 0.2, 1.5)

func CloseDoor(DoorPos : Vector3i) -> void:
	var cell = CurrentWorld.GetMapData().cells[DoorPos]
	var DoorDat = cell.Custom_Data["Door"]
	var OppositeDoorPos = DoorDat.OpossiteDoorMapPosition
	var oppositeCell = CurrentWorld.GetMapData().cells[OppositeDoorPos]
	var oppositeDoorData = oppositeCell.Custom_Data["Door"]
	CurrentWorld.ToggleDoor(DoorPos)
	
	DoorDat.Blocked = true
	oppositeDoorData.Blocked = true
	
	UIMan.MiniMp.OnBlockClosed(DoorPos)
	UIMan.MiniMp.OnBlockClosed(OppositeDoorPos)
	
	AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5, 0.2, 1.5)

func OpenDoor(DoorPos : Vector3i) -> void:
	var cell = CurrentWorld.GetMapData().cells[DoorPos]
	var DoorDat = cell.Custom_Data["Door"]
	var OppositeDoorPos = DoorDat.OpossiteDoorMapPosition
	var oppositeCell = CurrentWorld.GetMapData().cells[OppositeDoorPos]
	var oppositeDoorData = oppositeCell.Custom_Data["Door"]
	CurrentWorld.ToggleDoor(DoorPos)
	
	DoorDat.Blocked = false
	oppositeDoorData.Blocked = false

	UIMan.MiniMp.OnBlockOpened(DoorPos)
	UIMan.MiniMp.OnBlockOpened(OppositeDoorPos)
	
	AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5, 0.2, 1.5)

func BreakFloor(Pos : Vector3i) -> void:
	var cell = CurrentWorld.GetMapData().cells[Pos]
	if (cell.type == CellData.CELLTYPE.FALL):
		return
	
	Manequin.FallStarted.disconnect(BreakFloor.bind(Pos))
	CurrentWorld.BreakFloor(Pos)
	
	#cell.Custom_Data.clear("Trap")
	var Particle = CurrentWorld.FloorBreakParticles.instantiate() as SubEmmiterParticle3D
	CurrentWorld.add_child(Particle)
	Particle.position = Pos * CurrentWorld.MData.WorldScale
	Particle.StartEmmision()

#----------------------------------------------------------------
#Lock related

func LockPDoor(DoorPos : Vector3i) -> void:
	var LockPScene = load(LockPuzzleFilePath) as PackedScene
	var puzzle = LockPScene.instantiate() as LockPuzzle
	Fight.GetPlayer().CanMove = false
	Manequin.CanMove = false
	Node_Spawn_Loc.add_child(puzzle)
	puzzle.Finished.connect(DoorLockPuzzleFinished.bind(puzzle, DoorPos))

func LockP(ChestPos : Vector3i, HasKey : bool = false) -> void:
	var LockPScene = load(LockPuzzleFilePath) as PackedScene
	var puzzle = LockPScene.instantiate() as LockPuzzle
	puzzle.HasKey = HasKey
	Fight.GetPlayer().CanMove = false
	Manequin.CanMove = false
	Node_Spawn_Loc.add_child(puzzle)
	puzzle.Finished.connect(LockPuzzleFinished.bind(puzzle, ChestPos))

func DoorLockPuzzleFinished(_res : bool, puzzle : LockPuzzle, DoorPos : Vector3i) -> void:
	puzzle.queue_free()
	var oppositedoor = CurrentWorld.GetMapData().DoorList[DoorPos].OpossiteDoorMapPosition
	CurrentWorld.ToggleDoor(DoorPos)
	CurrentWorld.UpdateDoors()
	UIMan.MiniMp.OnDoorUnlocked(DoorPos)
	UIMan.MiniMp.OnDoorUnlocked(oppositedoor)
	AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
	AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, -5)
	Fight.GetPlayer().CanMove = true
	Manequin.CanMove = true
	MessageBox.RegisterEvent("Door unlocked")

func LockPuzzleFinished(_res : bool, puzzle : LockPuzzle, ChestPos : Vector3i) -> void:
	puzzle.queue_free()
	var cell = CurrentWorld.GetMapData().GetCell(ChestPos)
	
	var ChestDat = cell.Custom_Data["Chest"]
	var it = load(ChestDat.ContainedItem)
	
	cell.type = CellData.CELLTYPE.NORMAL
	cell.Custom_Data.erase("Chest")
	
	CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.CHESTS, [ChestPos])
	
	UIMan.MiniMp.OnDoorUnlocked(ChestPos)
	MessageBox.RegisterEvent("The chest was unlocked")
	var chAnim = load(chest_animation).instantiate() as ChestAnimation
	Node_Spawn_Loc.add_child(chAnim)
	chAnim.Init(it)
	await chAnim.Finished
	UIMan.Inv.AddItem(it)
	Fight.GetPlayer().CanMove = true
	Manequin.CanMove = true
	WorldTimeManager.Instance.StartTime()



#----------------------------------------------------------------
#Fight

#----------------------------------------------------------------

#Events

func EV_MovableFound(t : bool) -> void:
	if (Manequin.HoldingPosition == Vector3i.ZERO):
		Fight.TutorialMan.IndicateGrab(t)
		if (t):
			TutorialManager.Instance.PlayTextInstruction(TutorialManager.TutorialTypes.DRAG)

func EV_OnItemAdded(It : Item) -> void:
	if (It is KeyItem):
		match (It.Type):
			KeyItem.KeyItemType.WATER_BOOTS:
				BasePlayerManequin.CanWalkOnWater = true
			KeyItem.KeyItemType.LAVA_BOOTS:
				BasePlayerManequin.CanWalkOnLava = true
			KeyItem.KeyItemType.WING_BOOTS:
				BasePlayerManequin.CanWalkOverGaps = true
			KeyItem.KeyItemType.SHOVEL:
				TutorialManager.Instance.PlayTextInstruction(TutorialManager.TutorialTypes.SHOVEL)



func AtackEnviroment() -> void:
	CurrentWorld.MonsterMan.TakeAction()
	
	var Lookingposition = Manequin.position + Vector3(Helper.rotate_vector3i(Vector3.FORWARD, Manequin.GetLookDir().y,Vector3i(0,1,0)) * CurrentWorld.MData.WorldScale)
	#Lookingposition.y -= 1
	#var wscale = CurrentWorld.MData.WorldScale
	var LookingMapPos = Helper.PlayerPositionToMap(Lookingposition)
	print(LookingMapPos)
	var MapPos = Helper.PlayerPositionToMap(Manequin.position)
	
	var mapData : MapData = CurrentWorld.GetMapData()
	var cell = mapData.cells[MapPos]
	
	
	var Proj = playerCharacter.CharacterWeapon.Proj
	if (Proj != null):
		
		var CanShoot: bool = true
		if (Proj is ManaProjectile):
			CanShoot = playerCharacter.CurrentMana >= 5
			if (CanShoot):
				playerCharacter.DamageMana(Proj.ManaCost)
			else:
				MessageBox.RegisterEvent("Not enough mana", false, true)
				
		if (Proj is ItemProjectile):
			CanShoot = UIMan.Inv.HasItem(Proj.It)
			if (CanShoot):
				UIMan.Inv.RemoveItem(Proj.It)
			else:
				MessageBox.RegisterEvent("Not enough mana", false, true)
				
		if (CanShoot):
			var Trap = Proj.ProjectileScene.instantiate() as BaseTrap
			Trap.TogglePlayerEffect(false)
			Trap.ToggleEnemyEffect(false)
			#if (Trap is FireTrapProjectile):
				#Trap.ProjectileRange = 10
				#Trap.Speed = 5
			var T = Manequin.MagicProjectileLocation.global_transform
			
			CurrentWorld.TrapMan.AddCustom(T, Trap)
	var lookingCell = mapData.GetCell(LookingMapPos)
	if (lookingCell != null):
		if (lookingCell.HasData("Breakable")):
			if (Fight.GetPlayer().CurrentWeapon.TwoHanded):
				AudioManager.Instance.PlaySound(AudioManager.Sound.BREAK_WOOD, 0, 0.5)
				CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.BREAKABLES, [LookingMapPos])
				var Particle = CurrentWorld.BarrelBreakParticles.instantiate() as SubEmmiterParticle3D
				CurrentWorld.add_child(Particle)
				Particle.position = Lookingposition
				#Particle.position.y = 0
				Particle.StartEmmision()
				MessageBox.RegisterEvent("{0} breaks the barricade in front of him".format([playerCharacter.CharacterName]))
			else:
				MessageBox.RegisterEvent("Can't break barricade with current weapon")
				AudioManager.Instance.PlaySound(AudioManager.Sound.HIT_WOOD, -5, 0.5)
				
		if (lookingCell.HasData("SoftBreakable")):
			AudioManager.Instance.PlaySound(AudioManager.Sound.BREAK_WOOD, 0, 0.5)
			CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.SOFT_BREAKABLES, [LookingMapPos])
			var Particle = CurrentWorld.BarrelBreakParticles.instantiate() as SubEmmiterParticle3D
			CurrentWorld.add_child(Particle)
			Particle.position = Lookingposition
			#Particle.position.y = 0
			Particle.StartEmmision()
			MessageBox.RegisterEvent("{0} breaks the barricade in front of him".format([playerCharacter.CharacterName]))
		
		if (!cell.HasData("Walls") or !lookingCell.HasData("Walls")):
			return
		var crackedWall : WallData
		var lookingCrackedWall : WallData
		for g : WallData in cell.Custom_Data["Walls"]:
			if (g.Cracked):
				crackedWall = g
				break
		for g : WallData in lookingCell.Custom_Data["Walls"]:
			if (g.Cracked):
				lookingCrackedWall = g
				
		if (crackedWall != null and lookingCrackedWall != null):
			CurrentWorld.BreakWall(MapPos, crackedWall, LookingMapPos,lookingCrackedWall)
			var Particle = CurrentWorld.WallBreakParticles.instantiate() as SubEmmiterParticle3D
			CurrentWorld.add_child(Particle)
			var midpoint = (LookingMapPos + MapPos) * 0.5
			Particle.position = midpoint * Vector3(CurrentWorld.MData.WorldScale)
			#Particle.position.y += 0.5
			Particle.global_rotation = Manequin.GetLookDir()
			#Particle.position.y = 0
			Particle.StartEmmision()


func EV_MonsterKilled(MonGroup : MonsterGroup, _GoldReward : int) -> void:
	
	var Mon = MonGroup.Mon
	
	if (MonGroup.Drop != ""):
		MessageBox.RegisterEvent("{0} dropped an item".format([Mon.MonsterName]))
		var drop = load(MonGroup.Drop)
		UIMan.Inv.AddItem(drop)
		var chAnim =  load(Item_animation).instantiate() as ChestAnimation
		Node_Spawn_Loc.add_child(chAnim)
		chAnim.Init(drop)
		if (drop is KeyItem or drop is UnlockItem):
			MonGroup.Drop = ""
	
	if (Mon.Drop != ""):
		var r = randi_range(0,9)
		if (r == 0):
			#if (UIMan.Inv.HasSpace()):
			UIMan.Inv.AddItem(Mon.Drop)
			var chAnim =  load(Item_animation).instantiate() as ChestAnimation
			Node_Spawn_Loc.add_child(chAnim)
			chAnim.Init(load(MonGroup.Drop))


func EV_CharacterDeath(Char : Character) -> void:
	var Data : Dictionary = {
		"User" : Char,
		#"Team" : AliveCharacters,
	}
	var FightingMonster = Fight.GetCurrentEnemyCombatant()
	if (FightingMonster != null):
		#Data["EnemyTeam"] = FightingMonster.Spawns
		Data["Monster"] = FightingMonster
			
	UIMan.Inv.ApplyEffects(ItemEffect.EffectTiming.ON_DEATH, Data)

func EV_CharacterKilled(Char : Character) -> void:
	var Data : Dictionary = {
		"User" : Char,
		#"Team" : AliveCharacters,
	}
	var FightingMonster = Fight.GetCurrentEnemyCombatant()
	if (FightingMonster != null):
		#Data["EnemyTeam"] = FightingMonster.Spawns
		Data["Monster"] = FightingMonster
	UIMan.Inv.ApplyEffects(ItemEffect.EffectTiming.ON_DEATH, Data)

	#Char.ResetExp()

	MessageBox.RegisterEvent("{0} has died!".format([Char.CharacterName]))
	
	if (!playerCharacter.IsAlive()):
		for g in Fight.GetAllEnemyCombatants():
			g.Respawn(99)

		ConsumedByDarkness()

func EV_ItemUsed(It : Item) -> void:
	if (It is KeyItem):
		if (It.Type == KeyItem.KeyItemType.SHOVEL):
			Dig(Helper.PlayerPositionToMap(Vector3i(Manequin.position)))
	else: if (It is UnlockItem):
		if (InteractionCast.CurrentInteractable == null):
			MessageBox.RegisterEvent("Can't use this right now.")
		else: if (InteractionCast.CurrentInteractable.Name == InteractionCollisionShape.AreaNames.Door):
			var Dat : DoorData = InteractionCast.CurrentInteractable.DoorDat
			if (Dat.LockDat != null and Dat.LockDat.RequiredItem == It):
				var OppositeDoorPos = Dat.OpossiteDoorMapPosition
				CurrentWorld.ToggleDoor(Dat.DoorMapPosition)
				CurrentWorld.RemoveFrom(LevelMultimesh.LevelMultimeshTypes.LOCKS, [Dat.DoorMapPosition, OppositeDoorPos])
				
				#CurrentWorld.UpdateDoors()
				UIMan.MiniMp.OnDoorUnlocked(Dat.DoorMapPosition)
				UIMan.MiniMp.OnDoorUnlocked(OppositeDoorPos)
				AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
				MessageBox.RegisterEvent("Door unlocked")
				UIMan.Inv.RemoveItem(It)
		else: if (InteractionCast.CurrentInteractable.Name == InteractionCollisionShape.AreaNames.Chest):
			#LOCKED CHEST
			var Dat : ChestData = InteractionCast.CurrentInteractable.ChestDat
			if (Dat.TryUnlock(It)):
				UIMan.Inv.RemoveItem(It)
				UIMan.ToggleInventory()
				WorldTimeManager.Instance.StopTime()
				LockP(Dat.ChestMapPosition, true)
		else : if (InteractionCast.CurrentInteractable.Name == InteractionCollisionShape.AreaNames.Lever):
			var Dat : LeverData = InteractionCast.CurrentInteractable.LeverInfo
			if (Dat.Info.IsMissingPart and Dat.Info.MissingPart == It):
				UIMan.Inv.RemoveItem(It)
				Dat.Info.IsMissingPart = false
				CurrentWorld.UpdateLevers()
				MessageBox.RegisterEvent("The lever has been repaired")
				AudioManager.Instance.PlaySound(AudioManager.Sound.UNLOCK, -5)
				Fight.GetPlayer().ExtendHand()
		else:
			MessageBox.RegisterEvent("Can't use this right now.")
	else : if (It is WeaponItem):
		#if (Fight.InFight):
			#MessageBox.RegisterEvent("Can't switch weapon durring combat")
		#else:
		playerCharacter.CharacterWeapon = It.WeaponsRes
		Fight.GetPlayer().EquipWeapon(It.WeaponsRes)
		UIMan.Inv.ChangeWeapon(It.WeaponsRes)
		
	CurrentWorld.MonsterMan.TakeAction()
	var Data : Dictionary = {
		"User" : playerCharacter,
		#"Team" : AliveCharacters,
	}
	UIMan.Inv.ApplyEffectsOfItem(It ,ItemEffect.EffectTiming.ON_USE, Data)

#----------------------------------------------------------------



#----------------------------------------------------------------
#Save/Loading

func GetSaveData() -> Save:
	var S = Save.new()
	S.CurrentCurrency = UIMan.Inv.GoldAmmount
	S.WorldData = StoredWorlds
	S.WorldData[CurrentWorld.MData.LevelName] = CurrentWorld.GetMapData()
	S.PlayerLocation = Manequin.PlayerPos
	S.PlayerCharacter = playerCharacter
	S.InventoryContents = UIMan.Inv.InventoryContents
	S.CurrentWorld = CurrentWorld.MData.LevelName
	UIMan.MiniMp.StoreCurrentWorldData(CurrentWorld.MData.LevelName)
	S.MiniData = UIMan.MiniMp.StoredData
	S.Globals = Global_Manager.Globals
	return S
	
func LoadGame(Data : Save) -> void:
	StoredWorlds = Data.WorldData
	Global_Manager.Globals = Data.Globals
	UIMan.MiniMp.StoredData = Data.MiniData
	RegisteCharachter(Data.PlayerCharacter)
	
	var StoredData : MapData = StoredWorlds[Data.CurrentWorld]
	var NewWorld : Level = load(StoredData.level).instantiate()

	switch_levels(NewWorld, StoredData)
	await NewWorld.GenerationFinished
	
	for g in Data.InventoryContents:
		UIMan.Inv.AddItem(g, false)
	UIMan.Inv.AddGold(Data.CurrentCurrency)
	
	Manequin.call_deferred("Teleport", Data.PlayerLocation)
	

#----------------------------------------------------------------
#Death

func ConsumedByDarkness() -> void:
	Dead = true

	Manequin.CanMove = false
	
	var tw = get_tree().create_tween()
	tw.tween_property(StreesVignette, "shader_parameter/outerRadius", 0.0, 2)
	await tw.finished
	
	Fight.PlayerKilled()

	Manequin.CanMove = false
	
	Manequin.SetLookDir(PlayerLastRestDirection)
	Manequin.Teleport(Helper.MapToPlayerPosition(PlayerLastRestLocation))

	await get_tree().create_timer(1).timeout
	var tw2 = get_tree().create_tween()
	#tw2.set_ease(Tween.EASE_IN)
	#tw2.set_trans(Tween.TRANS_BACK)
	tw2.tween_property(StreesVignette, "shader_parameter/outerRadius", 3.0, 2)
	await tw2.finished
	#set_physics_process(true)
	#set_process_input(true)
	Fight.GetPlayer().CanMove = true
	Manequin.CanMove = true
	UIMan.Inv.LoseHalfGold()
	#CurrentWorld.MData.TimePassed(24)
	
	MessageBox.RegisterEvent("Lost conceousness, you wake up in a nearby shelter. Lost all exp and half your gold.")
	#for g in AliveCharacters:
	#SelectedCharacter.ResetExp()
	playerCharacter.Heal(99999999)
	playerCharacter.HealFatigue(9999)
	playerCharacter.HealMana(9999)
	Dead = false

var MapsToCompute : int
signal MapComputateFinished

func NewGame() -> void:
	PrecomputeMaps()
	await MapComputateFinished
#	for g in StartingCharacters.size():
	var newchar = StartingCharacter.duplicate(true)
	RegisteCharachter(newchar)
	
	for g in StartingItems:
		var It = load(g)
		UIMan.Inv.AddItem(It, false)
	
	var StoredData : MapData = StoredWorlds[StartingLevel]

	var NewWorld : Level = load(StoredData.level).instantiate()
	
	switch_levels(NewWorld, StoredData)
	
	await NewWorld.GenerationFinished
	TransitioningLevel = true
	StreesVignette.set_shader_parameter("outerRadius", 0.0)
	LevelTransitionFinished()

func PrecomputeMaps() -> void:
	Helper.Instance.FakeLoading(true, true, "Generating Worlds")
	for dir in MapStoreDirs:
		var Maps = ResourceLoader.list_directory(dir)
		#MapsToCompute = Maps.size()
		for file: String in Maps:
			if (file.contains("/")):
				continue
			MapsToCompute += 1
			var resource := load(dir + file) as PackedScene
			var M = resource.instantiate() as Map
			add_child(M)
			M.StartGenerationThread()
			M.GenerationFinished.connect(MapComputationFinished.bind(M))
		Helper.Instance.FakeLoading(false, true, "Generating Worlds")

func MapComputationFinished(M : Map) -> void:
	StoredWorlds[M.LevelName] =  M.Data
	M.queue_free()
	MapsToCompute -= 1
	if (MapsToCompute == 0):
		MapComputateFinished.emit()

#----------------------------------------------------------------
