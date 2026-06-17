@tool
extends LevelMultimesh
class_name TextMultimesh

@export var DialogueTriggerScene : PackedScene
func _ready() -> void:
	collider = Level.CurrentWallCollider.create_trimesh_shape()
	collider.backface_collision = true

func ProcessPosition(Data : MapData, pos : Vector3i, _r : RandomNumberGenerator = null) -> void:
	var cell = Data.GetCell(pos)
	
	if (!cell.HasData("Text")):
		return
	
	var dialogueData : DialogueContainer = cell.Custom_Data["Text"]
	var DialogueT = DialogueTriggerScene.instantiate() as DialogueTrigger
	DialogueT.Dialogues = dialogueData.duplicate()
	DialogueT.position = Level.CurrentWorldScale * pos
	QueueCollider(DialogueT)
	
	var data : Dictionary = {}
	data["Collision"] = DialogueT
	spawnList[pos] = [data]
	

func GetLayerType() -> LevelMultimeshTypes:
	return LevelMultimeshTypes.TEXT

func AddCollider(Collider : Node3D) -> void:
	add_child(Collider)
