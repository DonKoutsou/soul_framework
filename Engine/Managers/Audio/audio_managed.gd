extends Node

class_name AudioManager

@export var SoundLibrary : Dictionary[Sound, AudioStream]

static var Instance : AudioManager

var PlayingSounds : Array[Sound]

func _ready() -> void:
	Instance = self

func PlaySound(S : Sound, volume : float = 0, RandPitchAmm : float = 0, BasePitch : float = 1, Stack : bool = true, BusOverride : String = "SFX") -> void:
	if (!Stack):
		if (PlayingSounds.has(S)):
			return
		PlayingSounds.append(S)
	var Audio = SoundLibrary[S]
	var DeletableS = DeletableSound.new()
	add_child(DeletableS)
	DeletableS.bus = BusOverride
	DeletableS.stream = Audio
	DeletableS.pitch_scale = randf_range(BasePitch - RandPitchAmm, BasePitch + RandPitchAmm)
	DeletableS.volume_db = volume
	DeletableS.play()
	DeletableS.finished.connect(SoundEnded.bind(S))

func PlaySoundLocational(S : Sound, Position : Vector3, volume : float = 0, RandPitchAmm : float = 0, BasePitch : float = 1, Stack : bool = true, sourcesize : float = 10, BusOverride : String = "SFX") -> void:
	if (!Stack):
		if (PlayingSounds.has(S)):
			return
		PlayingSounds.append(S)
	var Audio = SoundLibrary[S]
	var DeletableS = DeletableSound3D.new()
	Stage.CurrentWorld.add_child(DeletableS)
	DeletableS.bus = BusOverride
	DeletableS.stream = Audio
	DeletableS.pitch_scale = randf_range(BasePitch - RandPitchAmm, BasePitch + RandPitchAmm)
	DeletableS.volume_db = volume
	DeletableS.unit_size = sourcesize
	DeletableS.play()
	DeletableS.global_position = Position
	DeletableS.finished.connect(SoundEnded.bind(S))

func SoundEnded(S : Sound) -> void:
	PlayingSounds.erase(S)

enum Sound{
	STEP,
	LEVELUP,
	DAMAGE,
	UIHOVER,
	WHOSH,
	SWORD_CLASH,
	EVADE,
	UNLOCK,
	LOCK_STUCK,
	COINS,
	HIT_WOOD,
	BREAK_WOOD,
	LADDER,
	MAGIC,
	STEP_DIRT,
	WALK,
	WALK_DIRT,
	WALK_WOOD,
	DRAG,
	JUMP,
	WATER_STEP,
	SEATH_IN,
	SEATH_OUT,
	DIG,
	DROP,
	LEVITATE,
	DOOR_OPEN,
	SHOUT_HUMAN,
	PAIN_HUMAN,
}
