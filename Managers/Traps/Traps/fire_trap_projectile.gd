extends BaseTrap

class_name FireTrapProjectile

@export var DeathP : PackedScene
@export var Speed : float
@export var ProjectileRange : float
@export var NodesToHide : Array[Node3D]
@export var OffsetNode : Node3D
@export var Visual : GPUParticles3D

var IsDead : bool = false

func _ready() -> void:
	call_deferred("SpawnExplosion")
	OffsetNode.position.z = Speed


func SpawnExplosion() -> void:
	var d = DeathP.instantiate() as GPUParticles3D
	get_parent().add_child(d)
	d.position = position
	d.emitting = true 
	d.get_child(0).volume_db = 0
	d.get_child(0).unit_size = 2
	d.get_child(0).pitch_scale = 2
	d.finished.connect(d.queue_free)

func Update(delta: float) -> void:
	if (IsDead):
		return
	var Offset = (OffsetNode.global_position - global_position) * delta
	ProjectileRange -= abs(Offset.length())
	global_position += Offset
	if (ProjectileRange <= 0):
		var d = DeathP.instantiate() as GPUParticles3D
		get_parent().add_child(d)
		d.position = position
		d.emitting = true
		d.get_child(0).volume_db = 0
		d.get_child(0).unit_size = 2
		d.get_child(0).pitch_scale = 2
		d.finished.connect(d.queue_free)
		#set_physics_process(false)
		IsDead = true
		if (Visual != null):
			Visual.emitting = false
		DestroySelf()

func _on_area_3d_body_entered(_body: Node3D) -> void:
	#queue_free()
	var d = DeathP.instantiate() as GPUParticles3D
	get_parent().add_child(d)
	d.position = position
	d.emitting = true
	d.get_child(0).unit_size = 2
	d.get_child(0).volume_db = 0
	d.get_child(0).pitch_scale = 2
	d.finished.connect(d.queue_free)
	#Helper.Instance.CallLater(queue_free, 1)
	#set_physics_process(false)
	IsDead = true
	Area.set_deferred("monitoring", false)
	if (Visual != null):
		Visual.emitting = false
	d.finished.connect(DestroySelf)
	#$DamageBuff.finished.connect(queue_free)
	for g in NodesToHide:
		g.visible = false
	
func _on_area_3d_area_entered(area: Area3D) -> void:
	if (IsDead):
		return
	if (area.get_parent() is FireTrapProjectile):
		return
	if (area.get_parent().get_parent() is BasePlayerManequin):

		var pl = area.get_parent().get_parent() as BasePlayerManequin
		pl.Damage(Map.TrapType.FIRE_TRAP, 10)
	
	
	var d = DeathP.instantiate() as GPUParticles3D
	get_parent().add_child(d)
	d.position = position
	d.emitting = true
	d.get_child(0).unit_size = 2
	d.get_child(0).volume_db = 0
	d.get_child(0).pitch_scale = 2
	d.finished.connect(d.queue_free)
	#Helper.Instance.CallLater(queue_free, 1)
	#set_physics_process(false)
	IsDead = true
	Area.set_deferred("monitoring", false)
	
	d.finished.connect(DestroySelf)
	for g in NodesToHide:
		g.visible = false
	if (Visual != null):
		Visual.emitting = false
