extends Node

class_name DialogueManager

signal CameraOverrideRequested(transform : Transform3D)
signal CameraOverrideStopped
signal ItemGiven(item : Item)
signal RecruitTeleportRequest(mapCharacter : MapCharacter, NewLocation : Map.LocationName, Pos : Vector3i)

var currentWorldName : Map.LocationName
var InDialogue : bool = false

static func Create(inv : Inventory) -> DialogueManager:
	var diagMan = DialogueManager.new()
	diagMan.ItemGiven.connect(inv.AddItem)
	return diagMan

func CurrentWorldChanged(newWorld : Level) -> void:
	currentWorldName = newWorld.MData.LevelName

func ManequinSpawned(playerManequin : BasePlayerManequin) -> void:
	CameraOverrideRequested.connect(playerManequin.OverrideCamPos)
	CameraOverrideStopped.connect(playerManequin.ReturnCam)

func NPC_MET(Char : MapCharacter, _Pos : Vector3i) -> void:
	var CurrentStage : RecruitStage = Char.Char.Stages[Char.Char.CurrentStage]
	
	if (CurrentStage is RecruitStage_TeleportStall):
		if (Helper.PlayerPositionToMap(Char.position) == CurrentStage.TeleportPos and currentWorldName == CurrentStage.TeleportLocation):
			Char.Char.CurrentStage += 1
			CurrentStage = Char.Char.Stages[Char.Char.CurrentStage]
		else:
			InDialogue = true
			Char.DoDialogue(CurrentStage.Dialogue)
			CameraOverrideRequested.emit(Char.LookLoc.global_transform)
			#Manequin.OverrideCamPos(Char.LookLoc.global_transform)
			Char.DialogueEnded.connect(RecruitDialogueEnded.bind(Char, false))
			return
	
		
	if (CurrentStage is RecruitStage_ItemGive):
		InDialogue = true
		Char.DoDialogue(CurrentStage.Dialogue)
		Char.GiveItem()
		CameraOverrideRequested.emit(Char.LookLoc.global_transform)
		#Manequin.OverrideCamPos(Char.LookLoc.global_transform)
		Char.DialogueEnded.connect(RecruitDialogueEnded.bind(Char))
		ItemGiven.emit(CurrentStage.ItemToGive)
		
	
	else: if (CurrentStage is RecruitStage_Teleport):
		InDialogue = true
		Char.DoDialogue(CurrentStage.Dialogue)
		CameraOverrideRequested.emit(Char.LookLoc.global_transform)
		#anequin.OverrideCamPos(Char.LookLoc.global_transform)
		Char.DialogueEnded.connect(RecruitDialogueEnded.bind(Char))
		RecruitTeleportRequest.emit(Char, CurrentStage.TeleportLocation, CurrentStage.TeleportPos)

	else: if (CurrentStage is RecruitStage_ItemRetrieve):
		InDialogue = true
		Char.DoDialogue(CurrentStage.Dialogue)
		CameraOverrideRequested.emit(Char.LookLoc.global_transform)
		#Manequin.OverrideCamPos(Char.LookLoc.global_transform)
		Char.DialogueEnded.connect(RecruitDialogueEnded.bind(Char))
		#UIMan.Inv.AddItem(CurrentStage.ItemToGive)
	else: if (CurrentStage is RecruitStage_Dialogue):
		InDialogue = true
		Char.DoDialogue(CurrentStage.Dialogue)
		CameraOverrideRequested.emit(Char.LookLoc.global_transform)
		#Manequin.OverrideCamPos(Char.LookLoc.global_transform)
		Char.DialogueEnded.connect(RecruitDialogueEnded.bind(Char))

func RecruitDialogueEnded(Char : MapCharacter, Progress : bool = true) -> void:
	Char.DialogueEnded.disconnect(RecruitDialogueEnded.bind(Char))
	CameraOverrideStopped.emit()
	#Manequin.ReturnCam()
	InDialogue = false
	if (Progress):
		Char.Char.CurrentStage += 1
