extends Node
class_name UISoundMan

var Sounds : Array[AudioStreamPlayer] = []

static var Instance : UISoundMan
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for sound : AudioStreamPlayer in get_children():
		Sounds.append(sound)

	Instance = self
	Refresh()

static func GetInstance() -> UISoundMan:
	return Instance

func AddSelf(But : Control) -> void:
	# DIGITAL BUTTONS
	if (But.is_in_group("DigitalButtons")):
		if (But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.pivot_offset = But.size/2
		But.connect("button_down", OnDigitalButtonClicked)
		But.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		But.mouse_entered.connect(OnButtonHovered)
		But.mouse_exited.connect(OnButtonHoverEnded)
	# DIGITAL BUTTONS WITH BOUNCE ON HOVER
	if (But.is_in_group("DigitalBouncingButton")):
		if (But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.pivot_offset = But.size/2
		But.connect("button_down", OnDigitalButtonClicked)
		But.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		But.mouse_entered.connect(OnBouncingButtonHovered.bind(But))
		But.mouse_exited.connect(OnBouncingButtonHoverEnded.bind(But))

func RemoveSelf(But : Control) -> void:
	# DIGITAL BUTTONS
	if (But.is_in_group("DigitalButtons")):
		if (!But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.disconnect("button_down", OnDigitalButtonClicked)
		But.mouse_entered.disconnect(OnButtonHovered)
		But.mouse_exited.disconnect(OnButtonHoverEnded)
	# DIGITAL BUTTONS WITH BOUNCE ON HOVER
	if (But.is_in_group("DigitalBouncingButton")):
		if (!But.is_connected("button_down", OnDigitalButtonClicked)):
			return
		But.disconnect("button_down", OnDigitalButtonClicked)
		But.mouse_entered.disconnect(OnBouncingButtonHovered)
		But.mouse_exited.disconnect(OnBouncingButtonHoverEnded)

func Refresh():
	var Digibuttons = get_tree().get_nodes_in_group("DigitalButtons")
	
	for g  in Digibuttons.size():
		var DigitalButton = Digibuttons[g] as Control
		if (DigitalButton.has_signal("button_down")):
			if (DigitalButton.is_connected("button_down", OnDigitalButtonClicked)):
				continue
				
			DigitalButton.connect("button_down", OnDigitalButtonClicked)
		if (DigitalButton.is_connected("mouse_entered", OnButtonHovered)):
				continue
		DigitalButton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		DigitalButton.mouse_entered.connect(OnButtonHovered)
		DigitalButton.mouse_exited.connect(OnButtonHoverEnded)
		#Digibuttons[g].connect("focus_entered", OnButtonHovered);
	
	var DigiBouncingbuttons = get_tree().get_nodes_in_group("DigitalBouncingButton")
	
	for g  in DigiBouncingbuttons.size():
		var DigitalButton = DigiBouncingbuttons[g] as Control
		if (DigitalButton.is_connected("button_down", OnDigitalButtonClicked)):
			continue
			
		DigitalButton.connect("button_down", OnDigitalButtonClicked)
		DigitalButton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		DigitalButton.mouse_entered.connect(OnBouncingButtonHovered.bind(DigitalButton))
		DigitalButton.mouse_exited.connect(OnBouncingButtonHoverEnded.bind(DigitalButton))
		#Digibuttons[g].connect("focus_entered", OnButtonHovered);

func OnBouncingButtonHovered(But : Control) -> void:
	Sounds[1].playing = true
	But.pivot_offset = But.size / 2
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(But, "scale", Vector2(1.05,1.05), 0.25)
	#But.scale = Vector2(1.1, 1.1)
	#But.z_index = 1

func OnBouncingButtonHoverEnded(But : Control):
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(But, "scale", Vector2(1,1), 0.25)
	#But.scale = Vector2(1, 1)
	#But.z_index = 0
	
func OnButtonHovered():
	Sounds[1].playing = true

func OnButtonHoverEnded():
	pass

func OnDigitalButtonClicked():
	Sounds[0].playing = true
