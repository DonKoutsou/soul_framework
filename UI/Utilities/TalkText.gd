extends Node3D

class_name TalkText

var talk_timer: Timer
var text_to_show: String = ""
var characters_showing: int = 0
var talking: bool = false
var char_par: bool = false            # Does parent have NPC methods?
var text_label: Label
var vsize: Vector2
#var audio: AudioStreamPlayer
var doing_forced_dialogue: bool = false

var char_interval := 0.06
var acc := 0.0

signal Finished

func _ready() -> void:

	talk_timer = Timer.new()
	talk_timer.one_shot = true
	talk_timer.wait_time = 2.0
	add_child(talk_timer)
	talk_timer.timeout.connect(turn_off)

	set_process(false)
	set_physics_process(false)
	#var c = CanvasLayer.new()
	
	text_label = Label.new()
	add_child(text_label)
	#text_label = $2DText as Label
	text_label.hide()
	#audio = $AudioStreamPlayer as AudioStreamPlayer


func talk(diag: String, forced: bool = false) -> void:

	#if char_par:
		#Player.GetInstance().BeingTalkedTo = true
		#get_parent().call("HeadLook", Player.GetInstance().GetHeadGlobalPos())
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talk_timer.stop()
	text_to_show = diag
	characters_showing = 0
	text_label.text = ""
	talking = true

	text_label.show()
	set_process(true)
	set_physics_process(true)

	vsize = get_viewport().get_visible_rect().size
	doing_forced_dialogue = forced
	acc = 0.0


func turn_off() -> void:
	talking = false
	text_to_show = ""
	
	#if char_par:
		#get_parent().call("ResetLook")
		#Player.GetInstance().BeingTalkedTo = false

	text_label.hide()
	set_physics_process(false)
	Finished.emit()
	#DialogueManager.GetInstance().OnDialogueEnded(doing_forced_dialogue)


func is_talking() -> bool:
	return talking


func _process(delta: float) -> void:
	acc -= delta
	if acc > 0.0:
		return
	acc = char_interval

	#var r := randi_range(85, 115)
	#audio.pitch_scale = float(r) / 100.0
	#audio.play()

	text_label.text = text_to_show.substr(0, characters_showing)
	characters_showing += 1

	if characters_showing >= text_to_show.length() + 1:
		talk_timer.start()
		set_process(false)


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return

	var world_pos: Vector3 = global_position
	var screen_pos: Vector2 = cam.unproject_position(world_pos)

	# Check if unproject_position returned bad values (e.g. offscreen)
	if !screen_pos.is_finite():
		text_label.visible = false
		return
	else:
		text_label.visible = true

	var Vsize: Vector2 = get_viewport().get_visible_rect().size

	# Center label horizontally, place above the position vertically
	screen_pos.x -= (text_label.size.x * 0.5)
	screen_pos.y -= text_label.size.y

	# Clamp so the label stays fully on screen
	screen_pos.x = clamp(screen_pos.x, 0.0, Vsize.x - text_label.size.x)
	screen_pos.y = clamp(screen_pos.y, 0.0, Vsize.y - text_label.size.y)

	text_label.position = screen_pos
