extends FightScene

class_name TestFight

@export var en : MonsterGroup
@export var pl : Character

func _ready() -> void:
	super()
	InputManager.ChangeMouse(Input.MouseMode.MOUSE_MODE_HIDDEN)
	en.CurrentHP = en.GetStat(CharacterStat.STATS.MAX_HP)
	pl.CurrentHP = pl.GetStat(CharacterStat.STATS.MAX_HP)
	
	RegisterPlayerCharacter(pl)
	$UIManager.AddNewCharacter(pl)
	EnemyMet(en)
	$UIManager.ToggleFight(true)
	
	pl.Killed.connect(EndFight)
	en.Killed.connect(EndFight)

func _process(delta: float) -> void:
	var FinalDelta = delta * WorldTimeManager.GameFrameTimeMulti
	Update(FinalDelta)
	$UIManager.Update(FinalDelta)

func _input(event: InputEvent) -> void:
	ProcessInput(event)

func EndFight() -> void:
	get_tree().quit()
