@tool
extends BaseTrap

class_name GuilotineTrap

@export var Speed : float
@export var BladeMesh : MeshInstance3D
@export var SwipeMesh : MeshInstance3D
@export var BladeSound : AudioStreamPlayer3D
@export var Damage : int = 10

var Offset : float = 0
var GoingUp : bool = true
var PlayedInSound : bool = false

var Tw : Tween
var SwipeTw : Tween

func _ready() -> void:
	BladeMesh.rotation.z = -PI
	call_deferred("THing")

func Update(delta: float) -> void:
	Tw.custom_step(delta)
	SwipeTw.custom_step(delta)

func THing() -> void:
	BladeSound.play()
	Tw = create_tween()
	Tw.set_ease(Tween.EASE_IN_OUT)
	Tw.set_trans(Tween.TRANS_BACK)
	Tw.tween_property(BladeMesh, "rotation", Vector3(0,0,PI), 1 / Speed)
	Tw.pause()
	Tw.finished.connect(DestroySelf)
	
	SwipeTw = create_tween()
	#SwipeTw.set_ease(Tween.EASE_IN)
	#SwipeTw.set_trans(Tween.TRANS_BACK)
	SwipeTw.tween_property(SwipeMesh, "blend_shapes/blendShape1.Closed", 1.0, (0.35 / Speed))
	SwipeTw.pause()
	SwipeTw.finished.connect(SwipeOn)

func SwipeOn() -> void:
	SwipeTw = create_tween()
	SwipeTw.set_ease(Tween.EASE_OUT)
	SwipeTw.set_trans(Tween.TRANS_BACK)
	SwipeTw.tween_property(SwipeMesh, "blend_shapes/blendShape1.Closed", 0.0, (0.25 / Speed))
	SwipeTw.pause()
	SwipeTw.finished.connect(SwipeOff)

func SwipeOff() -> void:
	#SwipeTw = null
	SwipeTw = create_tween()
	SwipeTw.set_ease(Tween.EASE_OUT)
	SwipeTw.set_trans(Tween.TRANS_BACK)
	SwipeTw.tween_property(SwipeMesh, "blend_shapes/blendShape1.Closed", 1.0, (0.25 / Speed))
	SwipeTw.pause()
	#SwipeTw.finished.connect(DestroySelf)

func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		var pl = area.get_parent().get_parent() as BasePlayerManequin
		pl.Damage(Map.TrapType.SPIKE_TRAP, Damage)
		#DestroySelf()
