extends CanvasLayer

class_name StartingMenu

signal StartPressed
signal LoadPressed
signal TestStartPressed
signal SettingsPressed

@export var PopM : PackedScene
@export var menuWorldScene : PackedScene
@export var Credits : Control
@export var Menu : Control
@export var SettingsMenu : PackedScene

var StartingMenuW : StartingMenuWorld

func _ready() -> void:
	StartingMenuW = menuWorldScene.instantiate()
	$SubViewportContainer/SubViewport.add_child(StartingMenuW)
	
	UISoundMan.GetInstance().Refresh()
	$ColorRect.modulate.a = 1.0
	$ColorRect.visible = true
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_EXPO)
	tw.tween_property($ColorRect, "modulate", Color(0.0, 0.0, 0.0, 0.0), 1.5)
	await tw.finished
	$ColorRect.visible = false
	InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)

func Hide() -> void:
	var tw = create_tween()
	tw.tween_property($ColorRect, "modulate", Color(1,1,1,1), 1.5)
	await tw.finished

func _on_start_pressed() -> void:
	var P = PopM.instantiate() as PopMenu
	add_child(P)
	P.Pop("Show Hints", true)
	P.Answered.connect(OnTutorialPicked)
	$Control.visible = false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_close_credits_pressed() -> void:
	Credits.visible = false
	Menu.visible = true
	StartingMenuW.SwitchCameraPos(0)

func _on_credits_pressed() -> void:
	Credits.visible = true
	Menu.visible = false
	StartingMenuW.SwitchCameraPos(1)
	

func OnTutorialPicked(T : bool) -> void:
	TutorialManager.ShowTutorial = T
	StartPressed.emit()


var LogoPressedAmm : int = 0

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("AtackLeft")):
		LogoPressedAmm += 1
		if (LogoPressedAmm == 5):
			TestStartPressed.emit()
			$Control.visible = false


func _on_load_pressed() -> void:
	TutorialManager.ShowTutorial = false
	#$Control.visible = false
	LoadPressed.emit()

func PlayIntro() -> void:
	$ColorRect.visible = true
	StartingMenuW.PlayIntro()
	await StartingMenuW.AnimFinished
	#StartingMenuW.SwitchCameraPos(2)


func _on_settings_pressed() -> void:
	var s = SettingsMenu.instantiate()
	add_child(s)
