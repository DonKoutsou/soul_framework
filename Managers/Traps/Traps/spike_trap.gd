extends BaseTrap

class_name SpikeTrap

@export var Speed : float
@export var SpikeMesh : MeshInstance3D
@export var SpikeOutSOund : AudioStream
@export var SpikeInSound : AudioStream

var Offset : float = 0
var GoingUp : bool = true
var PlayedInSound : bool = false

func _ready() -> void:
	SpikeMesh.scale.y = 0
	call_deferred("PlayerSound", true)

func PlayerSound(i : bool) -> void:
	var sound = DeletableSound3D.new()
	if (i):
		sound.stream = SpikeOutSOund
	else:
		sound.stream = SpikeInSound
	get_parent().get_parent().add_child(sound)
	sound.position = position
	sound.bus = "SFX"
	sound.play()
	sound.unit_size = 3
	sound.attenuation_filter_cutoff_hz = 3000

func Update(delta: float) -> void:
	if (GoingUp):
		Offset += delta * Speed
	else:
		Offset -= delta * Speed
		
	SpikeMesh.scale.y = smoothstep(0, 1, min(1, Offset))
	if (Offset >= 10):
		GoingUp = false
	if (Offset < 1 and GoingUp == false and !PlayedInSound):
		PlayedInSound = true
		PlayerSound(false)
		
	if (Offset <= 0 and GoingUp == false):
		DestroySelf()
		
func _on_area_3d_area_entered(area: Area3D) -> void:
	if (area.get_parent().get_parent() is BasePlayerManequin):
		var pl = area.get_parent().get_parent() as BasePlayerManequin
		pl.Damage(Map.TrapType.SPIKE_TRAP, 10)
		#DestroySelf()
