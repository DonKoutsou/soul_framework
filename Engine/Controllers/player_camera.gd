extends Camera3D

class_name PlayerCamera

@export var BaseFOV : float = 75.0
@export var MaxRotation : Vector3 = Vector3(PI, PI, PI)
@export var Master : bool = false

var PositionOverriden : bool = false
static var RotationToFocusOn : Vector3
var LocalRotationToFocusOn : Vector3

static var MastCamOffset : Vector3
static var MastCamRotOffset : Vector3

var StartingPosition : Vector3
var StartingRotation : Vector3
#static var breath_amplitude : float = 0.01 # How far up/down the camera moves
#static var breath_duration  : float = 0.1 # Time in seconds for a full cycle (in and out)
#static var curve_power     : float = 2.0  # Exponent for extra easing (try 2..4)

static var shake_intensity: float = 0
static var shake_duration: float = 0
static var shake_timer: float = 0.0
static var FOV_timer : float = 0.0

static var ShowRed : bool = false
#static var BreathUp : bool = false
#static var CurrentBreathOffset : float

var RedColorRect : ColorRect

func _ready() -> void:
	call_deferred("PostInit")
	
	var c = CanvasLayer.new()
	add_child(c)
	RedColorRect = ColorRect.new()
	RedColorRect.color = Color(0.95, 0.213, 0.16, 0.0)
	c.add_child(RedColorRect)
	RedColorRect.set_anchors_preset(Control.PRESET_FULL_RECT)
	RedColorRect.set_deferred("size", RedColorRect.get_viewport_rect().size)
	RedColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func PostInit() -> void:
	StartingPosition = global_position
	StartingRotation = global_rotation

static func start_shake(intensity: float, duration: float, Red : bool = false, DOFOV : bool = false):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	ShowRed = Red
	if (DOFOV):
		FOV_timer = duration

func _physics_process(delta: float) -> void:
	var FinalRotation : Vector3 = Vector3.ZERO
	
	if (!PositionOverriden):
		if (Master):
			MastCamOffset = global_position - StartingPosition
			MastCamRotOffset = get_parent_node_3d().global_rotation.rotated(Vector3(0,1,0), PI)
		else:
			FinalRotation += Vector3(-MastCamRotOffset.x, MastCamRotOffset.y, MastCamRotOffset.z)
			position = MastCamOffset

		#FinalRotation += RotationToFocusOn
		FinalRotation = rotation.move_toward(RotationToFocusOn + FinalRotation, delta * 10)
		rotation = FinalRotation
		
	#rotation = clamp(rotation, -MaxRotation, MaxRotation)
	if shake_timer > 0.0:
		shake_timer -= delta
		
		var shake_offset : float = randf_range(-shake_intensity, shake_intensity)
		var shake_offset2 : float = randf_range(-shake_intensity, shake_intensity)
		h_offset = move_toward(h_offset, shake_offset, delta)
		v_offset = move_toward(v_offset, shake_offset2, delta)
		
		if (ShowRed):
			RedColorRect.color.a = clamp(shake_timer, 0, 0.3)
	else:
		h_offset = 0
		v_offset = 0
		ShowRed = false
		RedColorRect.color.a = 0
	if (FOV_timer > 0.0):
		FOV_timer -= delta
		fov = BaseFOV - (sin(FOV_timer * 10) * 10)
	else:
		fov = BaseFOV
