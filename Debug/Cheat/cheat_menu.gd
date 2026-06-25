extends Control

class_name CheatMenu

static var Open : bool = false


func _ready() -> void:
	visible = false

func _exit_tree() -> void:
	Open = false

func _on_inf_hp_pressed() -> void:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.CurrentHP = 99999999

func _on_inf_stam_pressed() -> void:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	var Stat : CharacterStat = pl.ControllingCharacter.CharacterStats[CharacterStat.STATS.MAX_FATIGUE]
	Stat.StatValue = 9999999

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("Cheat")):
		visible = !visible
		Open = visible
		if (visible):
			InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)
		else:
			InputManager.ChangeMouse(Input.MOUSE_MODE_CAPTURED)


func _on_noclip_pressed() -> void:
	BasePlayerManequin.Instance.NoClip = !BasePlayerManequin.Instance.NoClip


func _on_shake_pressed() -> void:
	PlayerCamera.start_shake(0.02, 0.3, false, true)


func _on_respawn_enemies_pressed() -> void:
	Stage.CurrentWorld.MData.TimePassed(6)


func _on_freecam_pressed() -> void:
	Stage.ToggleFreecam()


func _on_enemy_action_trigger_pressed() -> void:
	Stage.CurrentWorld.MonsterMan.TakeAction()


func _on_walk_on_water_pressed() -> void:
	BasePlayerManequin.CanWalkOnWater = !BasePlayerManequin.CanWalkOnWater
	if BasePlayerManequin.CanWalkOnWater:
		MessageBox.RegisterEvent("Can now walk on water")
	else:
		MessageBox.RegisterEvent("Can't walk on water")


func _on_walk_on_lava_pressed() -> void:
	BasePlayerManequin.CanWalkOnLava = !BasePlayerManequin.CanWalkOnLava
	if BasePlayerManequin.CanWalkOnLava:
		MessageBox.RegisterEvent("Can now walk on lava")
	else:
		MessageBox.RegisterEvent("Can't walk on lava")

func _on_walk_on_gaps_pressed() -> void:
	BasePlayerManequin.CanWalkOverGaps = !BasePlayerManequin.CanWalkOverGaps
	if BasePlayerManequin.CanWalkOverGaps:
		MessageBox.RegisterEvent("Can now walk on gaps")
	else:
		MessageBox.RegisterEvent("Can't walk on gaps")


func _on_redo_current_map_pressed() -> void:
	#var m = Stage.CurrentWorld.MData
	#m.StartGenerationThread()
	#await m.GenerationFinished
	Stage.CurrentWorld.RedoMap()
	


func _on_spawn_reward_pressed() -> void:
	Stage.Isntance.SpawnReward()


func _on_upgrade_hp_pressed() -> void:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_HP)


func _on_upgrade_stamina_pressed() -> void:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_FATIGUE)


func _on_upgrade_mana_pressed() -> void:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_MANA)
