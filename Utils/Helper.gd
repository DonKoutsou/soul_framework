extends CanvasLayer

class_name Helper

@export var BlackLoadingRect : ColorRect
@export var LoadingUI : Control
@export var LoadingProgress : ProgressBar
@export var VersionLabel : Label

static var Instance : Helper
static var r : RandomNumberGenerator

var FakeLoadingHappening : bool = false

var loadProg : float
var loadTw : Tween

func _ready() -> void:
	Instance = self
	LoadingUI.visible = false
	BlackLoadingRect.visible = false
	set_physics_process(false)
	r = RandomNumberGenerator.new()
	VersionLabel.text = "Demo v{0}".format([ProjectSettings.get_setting("application/config/version")])
	

static func PlayerPositionToMap(Pos : Vector3i) -> Vector3i:
	@warning_ignore("integer_division")
	var MapPos = Vector3i(Pos / Level.CurrentWorldScale)
	return MapPos

static func load_asset(path : String) -> Resource:
	if OS.has_feature("export"):
		# Check if file is .remap
		if not path.ends_with(".remap"):
			return load(path)

		# Open the file
		var __config_file = ConfigFile.new()
		__config_file.load(path)

		# Load the remapped file
		var __remapped_file_path = __config_file.get_value("remap", "path")
		__config_file = null
		return load(__remapped_file_path)
	else:
		return load(path)

static func MapToPlayerPosition(Pos : Vector3i) -> Vector3i:
	var PlPos = Vector3i(Pos * Level.CurrentWorldScale)
	return PlPos

static func GetNameOfStat(stat : CharacterStat.STATS) -> String:
	var Name : String = ""
	match(stat):
		CharacterStat.STATS.MAX_HP:
			Name = "Health"
		CharacterStat.STATS.MAX_FATIGUE:
			Name = "Stamina"
		CharacterStat.STATS.MAX_MANA:
			Name = "Mana"
	return Name

#----------------------------------------------------
static func are_transforms_opposite(transform_a: Transform3D, transform_b: Transform3D) -> bool:
	var forward_a = -transform_a.basis.z.normalized()
	var forward_b = -transform_b.basis.z.normalized()
	var dot = forward_a.dot(forward_b)
	return dot < -0.99

#----------------------------------------------------
static func are_directions_opposite(Dir1 : float, Dir2 : float) -> bool:
	var forward_a = Vector2.LEFT.rotated(Dir1)
	var forward_b = Vector2.LEFT.rotated(Dir2)
	var dot = forward_a.dot(forward_b)
	return dot < -0.99


static func Vector2To3(vector : Vector2, fl : float) -> Vector3:
	return Vector3(vector.x, fl, vector.y)

static func Vector3To2(vector : Vector3) -> Vector2:
	return Vector2(vector.x, vector.z)
#----------------------------------------------------
static func Vector2iTo3(vector : Vector2i, fl : int) -> Vector3i:
	return Vector3i(vector.x, fl, vector.y)

#----------------------------------------------------
static func Vector3ITo2(vector : Vector3i) -> Vector2i:
	return Vector2i(vector.x, vector.z)

#----------------------------------------------------
static func rotate_vector2_by_vector(v: Vector2, rot: Vector2) -> Vector2:
	if (v == Vector2.ZERO):
		return rot
	return Vector2(
		v.x * rot.x - v.y * rot.y,
		v.x * rot.y + v.y * rot.x
	)

#----------------------------------------------------
# axis: "x", "y", or "z"
static func rotate_vector3i(vec: Vector3i, angle_radians: float, axis: Vector3i) -> Vector3i:
	var x = vec.x
	var y = vec.y
	var z = vec.z
	var cos_a = cos(angle_radians)
	var sin_a = sin(angle_radians)
	
	match axis:
		Vector3i.RIGHT:
			# Rotate around X axis (Y/Z plane)
			var new_y = y * cos_a - z * sin_a
			var new_z = y * sin_a + z * cos_a
			return Vector3i(x, round(new_y), round(new_z))
		Vector3i.UP:
			# Rotate around Y axis (X/Z plane)
			var new_x = x * cos_a + z * sin_a
			var new_z = -x * sin_a + z * cos_a
			return Vector3i(round(new_x), y, round(new_z))
		Vector3i.BACK:
			# Rotate around Z axis (X/Y plane)
			var new_x = x * cos_a - y * sin_a
			var new_y = x * sin_a + y * cos_a
			return Vector3i(round(new_x), round(new_y), z)
		_:
			push_error("Invalid axis specified!")
			return vec  # No rotation if invalid axis

static func GetRandomRotationSnapped(rand : RandomNumberGenerator = RandomNumberGenerator.new()) -> float:
	var index = rand.randi_range(0,4)
	var RandRot : float = 0
	match(index):
		0:
			RandRot = -PI
		1: 
			RandRot = -PI/2
		2: 
			RandRot = 0
		3:
			RandRot = PI / 2
		4: 
			RandRot = PI/2
	return RandRot
	
static func rotate_vector2i(vec: Vector2i, angle_radians: float) -> Vector2i:
	var cos_a = cos(angle_radians)
	var sin_a = sin(angle_radians)
	var x = vec.x * cos_a - vec.y * sin_a
	var y = vec.x * sin_a + vec.y * cos_a
	# Convert back to integer (use round, floor, or ceil as needed)
	return Vector2i(round(x), round(y))

static func AngleToDirection(angle: float) -> String:
	var directions = ["North","Northeast", "West", "Northwest",  "South", "Southwest","East", "Southeast"]
	var index = int(fmod((angle + PI/8 + TAU), TAU) / (PI / 4)) % 8
	return directions[index]

static func mapvalue(Val : float, Min : float, Max : float) -> float:
	return Min + (Max - Min) * Val

static func normalize_value(value: float, minimum: float, maximum: float) -> float:
	if minimum == maximum:
		return 0.0
	return (value - minimum) / (maximum - minimum)

static func GetYesOrNo() -> bool:
	return r.randi_range(0, 1) == 0

## Return the [AABB] of the node.
static func get_node_aabb(node : Node, exclude_top_level_transform: bool = true) -> AABB:
	var bounds : AABB = AABB()
  # Do not include children that is queued for deletion
	if node.is_queued_for_deletion():
		return bounds

  # Get the aabb of the visual instance
	if node is VisualInstance3D:
		bounds = node.get_aabb();

  # Recurse through all children
	for child in node.get_children():
		var child_bounds : AABB = get_node_aabb(child, false)
		if bounds.size == Vector3.ZERO:
			bounds = child_bounds
		else:
			bounds = bounds.merge(child_bounds)

	if !exclude_top_level_transform:
		bounds = node.transform * bounds

	return bounds

func LoadThreaded(File : String) -> SignalObject:
	var Sign = SignalObject.new()
	LoadingProgress.value = 0
	#var t = Thread.new()
	ResourceLoader.load_threaded_request(File, "", true, ResourceLoader.CACHE_MODE_REUSE)
	
	CallLater(_CheckForFinishedLoad.bind(Sign, File), 0.01)
	
	LoadingUI.visible = true
	BlackLoadingRect.visible = false
	set_physics_process(true)
	
	return Sign

func FakeLoading(t : bool, ShowBlack : bool = false, CustomText : String = " Loading Stuff") -> void:
	set_physics_process(t)
	DotAmmount = 0
	LoadingUI.visible = t
	BlackLoadingRect.visible = ShowBlack
	LoadingUI.get_node("VBoxContainer/HBoxContainer/Label").text = CustomText
	FakeLoadingHappening = t

func SetLoadingProgress(newProg : float) -> void:
	LoadingProgress.value = newProg
	if (loadTw != null):
		loadTw.kill()

func UpdateLoadingProgress(newProg : float) -> void:
	if (newProg != LoadingProgress.value):
		if (loadTw != null):
			loadTw.kill()
		loadTw = create_tween()
		loadTw.tween_property(LoadingProgress, "value", newProg, 0.5)

var DotAmmount : int = 0
var d = 0.2
func _physics_process(delta: float) -> void:
	LoadingUI.get_node("TextureRect").rotation += delta * 4
	d -= delta
	if (d > 0):
		return
	d = 0.2
	var t = ""
	for g in DotAmmount:
		t += "."
	LoadingUI.get_node("VBoxContainer/HBoxContainer/Label2").text = t
	DotAmmount += 1
	if DotAmmount > 3:
		DotAmmount = 0

func _CheckForFinishedLoad(Sign : SignalObject, File : String) -> void:
	var prog : Array = []
	var Status = ResourceLoader.load_threaded_get_status(File, prog)
	loadProg = prog[0] * 100
	if (Status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		_LoadFinished(Sign, ResourceLoader.load_threaded_get(File))

	else:
		CallLater(_CheckForFinishedLoad.bind(Sign, File), 0.1)

		#Sign.Progressed.emit(prog[0])
	if (loadProg != LoadingProgress.value):
		if (loadTw != null):
			loadTw.kill()
		loadTw = create_tween()
		loadTw.tween_property(LoadingProgress, "value", loadProg, 0.5)

func _LoadFinished(Sign : SignalObject, File : PackedScene) -> void:
	LoadingUI.visible = FakeLoadingHappening
	set_physics_process(FakeLoadingHappening)
	Sign.Finished.emit(File)

func CallLater(Call : Callable, t : float = 1) -> void:
	await get_tree().create_timer(t).timeout
	Call.call()

func wait(secs : float) -> Signal:
	return get_tree().create_timer(secs).timeout
