@tool
extends Interactable

class_name MapCharacter

@export var Char : Character
@export var LookPivot : Node3D
@export var Skel : Skeleton3D
@export var Talkt : TalkText
@export var modif : Fight_Animation_Modifier
@export var lookModif : LookAtModifier3D
@export var LightPartScene : PackedScene
@export var HandPlacement : Node3D
@export var LookLoc : Node3D

var pl : BasePlayerManequin

var PrevLookRot : Vector3

static var OverrideLook : bool = false

var Parts : Array[LightPart]

signal DialogueEnded()

func _ready() -> void:
	modif.CurrentState = FightCharacter.CharacterState.IDLE

func GiveItem() -> void:
	modif.CurrentState = FightCharacter.CharacterState.EXTEND_HAND

func DoDialogue(Diag : String) -> void:
	Talkt.talk(Diag)
	await Talkt.Finished
	#Char.CurrentStage += 1
	DialogueEnded.emit()

func ConfigureCharacter(character : Character) -> void:
	Char = character
	var vis : PackedScene = await Helper.Instance.LoadThreaded(character.Visuals).Finished
	var visuals = vis.instantiate()
	ApplyVisualsToSkeleton(visuals)

func ApplyVisualsToSkeleton(visuals : Node3D) -> void:
	Skel.add_child(visuals)
	for g : MeshInstance3D in visuals.get_children():
		g.skeleton = g.get_path_to(Skel)

func HandExtended() -> void:
	var p = LightPartScene.instantiate() as LightPart
	p.SpeedOverride = 0.5
	p.TurnPower = 10
	p.Destination = pl.RewardLocation
	#p.Finished.connect(UT_Stage.EV_CharacterStressHealed.bind(1, ""))
	p.Died.connect(ParticleDied.bind(p))
	get_parent().add_child(p)
	p.global_position = HandPlacement.global_position
	p.position.y += 0.1
	#p.position = LightSpawnPosition.position
	await Helper.Instance.wait(1)
	Parts.append(p)
	modif.CurrentState = FightCharacter.CharacterState.IDLE

func ParticleDied(Part : LightPart) -> void:
	Parts.erase(Part)

func Update(delta: float) -> void:
	
	for g in Parts:
		g.Update(delta)
		
	if (pl != null):
		look_at(pl.global_position, Vector3.UP, true)
		#LookPivot.look_at(pl.global_position, Vector3.UP, true)
		
		#PrevLookRot = PrevLookRot.move_toward(LookPivot.rotation, delta)
		
		#var newrot : float = 0
		#if (PrevLookRot.y < -PI/4):
		#	newrot = PrevLookRot.y + (-PI/4)
		#else: if (PrevLookRot.y > PI/4):
		#	newrot = PrevLookRot.y + (PI/4)
		#rotation.y = move_toward(rotation.y, newrot, delta)
		
		#print(rotation)
		#var rot = Quaternion.from_euler(Vector3(PrevLookRot.x,clamp(PrevLookRot.y, -PI /4, PI/4),0))
		#Skel.set_bone_pose_rotation(31, rot)
	else:
		return
		#rotation.y = move_toward(rotation.y, 0, delta)
		
		#PrevLookRot = PrevLookRot.move_toward(Vector3.ZERO, delta)
		#var rot = Quaternion.from_euler(Vector3(PrevLookRot.x,PrevLookRot.y,0))
		#Skel.set_bone_pose_rotation(31, rot)


func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		
		pl = area.get_parent().get_parent()
		lookModif.target_node = lookModif.get_path_to(pl)
		#OverrideLook = false
		#var PlChar = pl.ControllingChar
		#var PossibleLines : Array[String]
		
		#var HpPercent = pl.ControllingChar.GetHPPercent()
		#if HpPercent < 20:
			#PossibleLines.append("Almost didn't make it there did we ?")
		#if char.stre
		
		#if (TimesMet == 0):
		Talkt.talk("Hello Stranger....")
		#else:
			#PossibleLines.append("Welcome back Stranger....")
			##talkt.talk("Welcome back Stranger....")
			#talkt.talk(PossibleLines.pick_random())
		#TimesMet += 1


func _on_area_3d_area_exited(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		pl = null
		lookModif.target_node = ""
		#OverrideLook = false
