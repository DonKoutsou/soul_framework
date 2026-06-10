extends BaseTrap

class_name FireGeyser

@export var Speed : float
@export var Lifetime : float = 1.0

var Parts : Array[GPUParticles3D]
var PartsFinished : int = 0

func _ready() -> void:
	var t = get_tree().create_timer(Lifetime)
	t.timeout.connect(LifetimeEnded)
	
	for g in get_children():
		if (g is GPUParticles3D):
			Parts.append(g)
			g.finished.connect(OnPartFinished)
	#call_deferred("PlayerSound", true)

func LifetimeEnded() -> void:
	var t = get_tree().create_timer(Lifetime)
	t.timeout.connect(DestroySelf)
	$Area3D.get_child(0).disabled = true
	for g in Parts:
		g.emitting = false

func OnPartFinished() -> void:
	PartsFinished -= 1
	if (PartsFinished == 0):
		DestroySelf()

		
func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		var pl = area.get_parent().get_parent() as BasePlayerManequin
		pl.Damage(Map.TrapType.FIREPIT_TRAP, 10)
		#DestroySelf()
