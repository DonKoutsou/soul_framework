extends Node3D

class_name FightWorld3D


@export var Pl : Player
#@export var BG : Control
@export var BGMesh : MeshInstance3D
@export var env : WorldEnvironment

@export_file("*.tscn") var EnemyScene : String
var En : Enemy
var BGMat : ShaderMaterial
signal EnemyIntroFinished
var s : Skin

func Update(delta : float) -> void:
	var curTime = BGMat.get_shader_parameter("TimeOffset")
	if (curTime == null):
		return
	BGMat.set_shader_parameter("TimeOffset", curTime + delta)
	if (En != null):
		En.UpdateAnims(delta)
		En.Update(delta)

func _ready() -> void:
	BGMat = BGMesh.material_override as ShaderMaterial
	BGMat.set_shader_parameter("alpha_scale", 0)


func SpawnEnemy(actor : MonsterGroup) -> void:
	var scene : PackedScene = await Helper.Instance.LoadThreaded(EnemyScene).Finished
	En = scene.instantiate()
	En.Target = Pl
	En.ControllingCharacter = actor
	await En.ControllingCharacterSet
	En.EquipWeapon(actor.CharacterWeapon)
	add_child(En)
	En.position = $EnemySpawnLoc.position
	
	

func EnemyIntroAnim() -> void:
	En.visible = true
	
	En.position.z = -20
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property(En, "position", $EnemySpawnLoc.position, 0.5)
	#En.HideWeapons()
	En.CanMove = false
	Pl.CanMove = false
	tw.finished.connect(EnemyIntroEnd)

func EnemyIntroEnd() -> void:
	En.CanMove = true
	Pl.CanMove = true
	EnemyIntroFinished.emit()
	
func UpdateAlpha(A : float) -> void:
	BGMat.set_shader_parameter("alpha_scale", A)
	#BG.visible = A > 0
	#BGMesh.visible = A > 0
	env.environment.fog_height_density = A * 16
	env.environment.fog_density = A
