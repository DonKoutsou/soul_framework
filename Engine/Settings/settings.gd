extends ColorRect

class_name Settings

@export var BrighnessSlider : HSlider
@export var ContrastSlider : HSlider
@export var FullScreenCheckbox : CheckBox
@export var SoundSlider : HSlider
@export var MusicSoundSlider : HSlider
@export var VSync : CheckBox
@export var MinimapBox : CheckBox
@export var DOFBOX : CheckBox
@export var HeadBobBox : CheckBox

#static var Env = preload("res://Enviroments/MasterEnviroment.tres")
static var CameraAttribures = [load("res://Engine/Enviroments/CameraSettings/FightPlayerCameraAttribures.tres"), load("res://Engine/Enviroments/CameraSettings/PlayerManequinCameraAttribures.tres"), load("res://Engine/Enviroments/CameraSettings/StartingWorldCameraAtributes.tres")]

signal Close

func _ready() -> void:
	UISoundMan.Instance.Refresh()
	#BrighnessSlider.set_value_no_signal(Env.adjustment_brightness)
	#ContrastSlider.set_value_no_signal(Env.adjustment_contrast)
	FullScreenCheckbox.set_pressed_no_signal(DisplayServer.window_get_mode() == 3)
	SoundSlider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
	MusicSoundSlider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))))
	VSync.set_pressed_no_signal(DisplayServer.window_get_vsync_mode() == 1)
	MinimapBox.set_pressed_no_signal(Minimap.ShowMinimap)
	DOFBOX.set_pressed_no_signal(CameraAttribures[0].dof_blur_amount > 0)
	HeadBobBox.set_pressed_no_signal(Player.HeadBob)

func _on_brighness_slider_value_changed(value: float) -> void:
	pass
	#Env.adjustment_brightness = value

func _on_contrast_slider_value_changed(value: float) -> void:
	pass
	#Env.adjustment_contrast = value

func _on_full_screen_box_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_sound_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))


func _on_v_sync_box_toggled(toggled_on: bool) -> void:
	var mode : DisplayServer.VSyncMode = DisplayServer.VSyncMode.VSYNC_DISABLED
	if (toggled_on):
		mode = DisplayServer.VSyncMode.VSYNC_ENABLED
	else:
		mode = DisplayServer.VSyncMode.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)


func _on_minimap_box_toggled(toggled_on: bool) -> void:
	Minimap.ShowMinimap = toggled_on
	Minimap.Instance.ToggleMinimap(Minimap.Instance.MapBig)


func _on_button_pressed() -> void:
	Close.emit()


func _on_music_sound_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func SaveSettings() -> void:
	var SettingsSaveFile = SettingsSave.new()
	SettingsSaveFile.FullScreen = DisplayServer.window_get_mode() == 3
	SettingsSaveFile.MasterSoundVolume = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	SettingsSaveFile.MusicVolume = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	SettingsSaveFile.VSync = DisplayServer.window_get_vsync_mode() == 1
	SettingsSaveFile.ShowMinimap = Minimap.ShowMinimap
	SettingsSaveFile.DOF = CameraAttribures[0].dof_blur_amount > 0
	#SettingsSaveFile.Brightness = Env.adjustment_brightness
	#SettingsSaveFile.Contrast = Env.adjustment_contrast
	SettingsSaveFile.HeadBob = Player.HeadBob
	ResourceSaver.save(SettingsSaveFile, "user://Settings.tres")

static func LoadSettings() -> void:
	if (!FileAccess.file_exists("user://Settings.tres")):
		return
	
	var sav = load("user://Settings.tres") as SettingsSave
	
	if (sav.FullScreen):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	var mode : DisplayServer.VSyncMode = DisplayServer.VSyncMode.VSYNC_DISABLED
	if (sav.VSync):
		mode = DisplayServer.VSyncMode.VSYNC_ENABLED
	else:
		mode = DisplayServer.VSyncMode.VSYNC_DISABLED
		
	DisplayServer.window_set_vsync_mode(mode)
	
	Minimap.ShowMinimap = sav.ShowMinimap
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(sav.MasterSoundVolume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(sav.MusicVolume))
	
	for g in CameraAttribures:
		if (sav.DOF):
			g.dof_blur_amount = 0.1
		else:
			g.dof_blur_amount = 0.0
	
	#Env.adjustment_brightness = sav.Brightness
	#Env.adjustment_contrast = sav.Contrast
	Player.HeadBob = sav.HeadBob
	
func _on_dof_box_toggled(toggled_on: bool) -> void:
	for g in CameraAttribures:
		if (toggled_on):
			g.dof_blur_amount = 0.1
		else:
			g.dof_blur_amount = 0.0

func _on_head_bob_box_toggled(toggled_on: bool) -> void:
	Player.HeadBob = toggled_on
	
	if (Stage.Isntance == null):
		return
		
	Stage.Isntance.Fight.ToggleHeadBob(toggled_on)
