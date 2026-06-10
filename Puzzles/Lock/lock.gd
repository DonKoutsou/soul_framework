extends SubViewportContainer

class_name LockPuzzle

signal Finished(Resault : bool)

@export var KeyHand : Node3D
@export var LockpickHands : Array[Node3D]

@export var LockPick : Node3D
@export var LockRotatingBody : Node3D
@export var Anim : AnimationPlayer

var PuzzleSolution : int
var MovingPick : bool = false
var allowed : float
var HasKey : bool = false

@export var Sounds : Dictionary[String, AudioStreamPlayer] = {
	"StopLockSound": null,
	"OpenLockSound": null,
	"SolvedSound": null
}

func _ready():
	ProduceSolution()
	KeyHand.visible = HasKey
	for g in LockpickHands:
		g.visible = !HasKey

func ProduceSolution():
	if (HasKey):
		var tw = create_tween()
		tw.set_ease(Tween.EASE_IN)
		tw.set_trans(Tween.TRANS_QUINT)
		tw.tween_property(KeyHand, "position", Vector3.ZERO, 1.0)
		PuzzleSolution = 0
	else:
		PuzzleSolution = randi_range(-91, 91)

func GetAllowedRotation() -> float:
	var lockpickrot = rad_to_deg(LockPick.rotation.y)
	var dif = abs(lockpickrot - PuzzleSolution)

	if dif < 5:
		return 90

	var alowed = 90 - min(90, dif)
	return alowed

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var pos = event.relative
		var rot = LockPick.rotation
		rot.y = clamp(rot.y - pos.x / 80, deg_to_rad(-90), deg_to_rad(90))
		LockPick.rotation = rot

	elif event is InputEventJoypadMotion:
		var pos = event.relative
		#var pos = Vector2(
		#	Input.get_action_strength("CameraRight") - Input.get_action_strength("CameraLeft"),
		#	Input.get_action_strength("CameraDown") - Input.get_action_strength("CameraUp")
		#).limit_length(2)

		pos = pos * 10
		var rot = LockPick.rotation
		rot.y = clamp(rot.y - pos.x / 80, deg_to_rad(-90), deg_to_rad(90))
		LockPick.rotation = rot

func _process(_delta):
	if Input.is_action_pressed("AtackLeft"):
		MovingPick = true
		allowed = GetAllowedRotation()
	else:
		MovingPick = false
		Sounds["StopLockSound"].stop()
		
	if MovingPick:
		var rot = LockRotatingBody.rotation
		rot.y = max(rot.y - 0.05, deg_to_rad(-allowed))
		print(allowed)
		print(rad_to_deg(rot.y))
		if is_equal_approx(rot.y, deg_to_rad(-90)) :
			PuzzleSolved()
			print("solved")
			return
		else: if rot.y == deg_to_rad(-allowed):
			Anim.play("Twitch")

			if !Sounds["StopLockSound"].is_playing():
				Sounds["StopLockSound"].play()

		if rot.y == LockRotatingBody.rotation.y:
			Anim.play("Twitch")
			if !Sounds["StopLockSound"].is_playing():
				Sounds["StopLockSound"].play()
			Sounds["OpenLockSound"].stop()
		else : if !Sounds["OpenLockSound"].is_playing():
			Sounds["OpenLockSound"].play()

		LockRotatingBody.rotation = rot
	else:
		var rot = LockRotatingBody.rotation
		rot.y = min(rot.y + 0.05, 0)
		LockRotatingBody.rotation = rot

		if rot.y != 0 and !Sounds["OpenLockSound"].is_playing():
			Sounds["OpenLockSound"].play()
		else:
			Sounds["OpenLockSound"].stop()

func PuzzleSolved():
	Anim.play("RemovePicks")
	set_process(false)
	set_process_input(false)
	Sounds["SolvedSound"].play()
	Sounds["OpenLockSound"].stop()
	
	await Helper.Instance.wait(1)
	Finished.emit(true)
