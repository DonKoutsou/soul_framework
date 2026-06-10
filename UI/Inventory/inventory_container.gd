extends PanelContainer

class_name InventoryContainer

#@export var Icon : TextureRect
#@export var L : Label
@export var Cam : Camera3D
@export var EquippedLabel : Label
@export var amount_label: Label
@export var CombinationPanel : ColorRect
@export var desc : RichTextLabel

var ItemVisual : Node3D
var ContainedItem : Item

var Ammount : int

signal Selected
signal Unselected
signal Pressed

func _ready() -> void:
	EquippedLabel.visible = false
	#set_physics_process(false)
	#get_tree().create_timer(2).timeout.connect(Init)
	call_deferred("Init")

func ToggleEquipped(t : bool) -> void:
	EquippedLabel.visible = t

func ToggleCombination(t : bool) -> void:
	CombinationPanel.visible = t

func _physics_process(delta: float) -> void:
	$Control/VBoxContainer/SubViewportContainer/SubViewport/Node3D.rotation.y += delta * 2

func Init() -> void:
	pivot_offset = Vector2(32, 32)

func AddItem(It : Item) -> void:
	if (ItemVisual != null):
		ItemVisual.queue_free()
		
	if (It is WeaponItem):
		ItemVisual = It.WeaponsRes.WeaponScene.instantiate()
		$Control/VBoxContainer/SubViewportContainer/SubViewport.add_child(ItemVisual)
	else:
		ItemVisual = MeshInstance3D.new()
		ItemVisual.mesh = It.Model
		$Control/VBoxContainer/SubViewportContainer/SubViewport.add_child(ItemVisual)
		ItemVisual.set_surface_override_material(0, It.ModelMat)
		
	var pos = calculate_camera_position_for_aabb(Helper.get_node_aabb(ItemVisual), Cam.fov, 1.0)
	#Model.position.x = -It.Model.get_aabb().position.x / 2.0
	center_mesh_instance()
	Cam.position = pos
	ContainedItem = It
	UpdateAmm(true)
	
	var t = "{0}[p]{1}".format([It.ItemName, It.GetItemDesc()])
	desc.text = t

var CurrentlyScrolledLine : int = 0
func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("zoom_in")):
		CurrentlyScrolledLine = max(0, CurrentlyScrolledLine - 1)
	if (event.is_action_pressed("zoom_out")):
		CurrentlyScrolledLine = min(desc.get_line_count(), CurrentlyScrolledLine + 1)

func center_mesh_instance() -> void:
	if ItemVisual== null:
		return
	
	var aabb: AABB = Helper.get_node_aabb(ItemVisual)
	var center: Vector3 = aabb.position + aabb.size * 0.5
	center *= Vector3(1,0,1)
	if (aabb.size.x == aabb.size.z):
		ItemVisual.rotation.x = 0.1
	else:
		ItemVisual.rotation.x = 0
	# Move the mesh so its center is at (0, 0, 0)
	ItemVisual.position = -center

func SetAmm(i : int) -> void:
	Ammount = i
	amount_label.text = var_to_str(Ammount) + "X"
	amount_label.visible = Ammount > 1

func UpdateAmm(t : bool) -> void:
	if (t):
		Ammount += 1
	else:
		Ammount -= 1
	amount_label.text = var_to_str(Ammount) + "X"
	amount_label.visible = Ammount > 1

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.9,0.9), 0.25)
	#z_index = 1
	
	Selected.emit()
	set_physics_process(true)
	AudioManager.Instance.PlaySound(AudioManager.Sound.UIHOVER, -15)
	
	

func _on_mouse_exited() -> void:
	set_physics_process(false)
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1.0,1.0), 0.25)
	#z_index = 0
	
	Unselected.emit()


func _on_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("AtackLeft")):
		Pressed.emit()

		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2(1.05,1.05), 0.10)
		await tw.finished
		var tw2 = create_tween()
		tw2.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_BACK)
		tw2.tween_property(self, "scale", Vector2(0.95,0.95), 0.10)

func calculate_camera_position_for_aabb(aabb: AABB, fov_degrees: float, aspect: float, margin: float = 1.1) -> Vector3:
	var center = aabb.position + aabb.size * 0.5
	var height = aabb.size.y
	var width = aabb.size.x
	var depth = aabb.size.z
	# Determine whether vertical or horizontal framing is tighter
	var fov_rad = deg_to_rad(fov_degrees)
	var vertical_extent = height
	var horizontal_extent = width / aspect

	var max_extent = max(vertical_extent, horizontal_extent) * margin

	# Calculate required distance from center (using perspective projection math)
	var distance = max_extent * 0.5 / tan(fov_rad * 0.5)

	# Assuming camera looks along -Z and is upright (no tilt)
	var camera_position = center + Vector3(0, 0, distance + depth)

	return camera_position
