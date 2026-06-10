extends PanelContainer

class_name CharacterSheet

@export var CharacterNameLabel : Label
@export var CharacterStatLabel : RichTextLabel
@export var CharacterHealthBar : ProgressBar
@export var CharacterHealthBar2 : ProgressBar
@export var CharacterHealthLabel : Label
@export var CharacterStaminaBar : ProgressBar
@export var CharacterStaminaBar2 : ProgressBar
@export var CharacterStaminaLabel : Label
@export var CharacterManaBar : ProgressBar
@export var CharacterManaBar2 : ProgressBar
@export var CharacterManaLabel : Label
@export var CharacterManaText : Label
#@export var AtackBar : ProgressBar
@export var DeathPanel : Panel
@export var Portrait : TextureRect
#@export var NumLabel : Label
@export var SlashAnim : PackedScene
@export var FloaterParent : Control
@export var FloaterParentBot : Control
@export var StunnTex : TextureRect
#@export var LevelText : Label

@export var DoAtackAnimations : bool = true

var CurrentChar : Character

var HealthTween : Tween
var StaminaTween : Tween
var ManaTween : Tween

var alpha : float = 10.0

func _physics_process(delta: float) -> void:
	alpha -= delta * 4
	modulate.a = clamp(alpha, 0, 1)

func SetCharacter(Char : Character, _Num : int) -> void:
	CurrentChar = Char
	#if (NumLabel != null):
		#NumLabel.visible = Num > -1
		#NumLabel.text = var_to_str(Num)
	
	#Char.Init()
	if (CharacterNameLabel != null):
		CharacterNameLabel.text = Char.CharacterName
	
	#if (LevelText != null):
		#LevelText.text = var_to_str(Char.CharacterLevel)
	
	if (CharacterStatLabel != null):
		var stattext : String = ""
		for g in CharacterStat.STATS.values():
			stattext += "[img={16}x{16}]{0}[/img]|{1}".format([CharacterStat.GetIconForStat(g), Char.GetStat(g)])
			if (g < CharacterStat.STATS.keys().size() - 1):
				stattext += "\n"
		CharacterStatLabel.text = stattext
	
	#Char.LevelChanged.connect(LevelGained)
	#Char.ExpGained.connect(StatsUpdated.bind(Char))
	Char.Damaged.connect(CharacterDamaged.bind(Char))
	Char.Killed.connect(CharacterKilled)
	Char.Healed.connect(Healed.bind(Char))
	Char.Picked.connect(CharacterPicked)
	
	Char.StatsUpgraded.connect(StatsUpdated.bind(CurrentChar))
	CurrentChar.FatigueHealed.connect(FatigueHealed.bind(CurrentChar))
	CurrentChar.FatigueDamaged.connect(FatigueDamaged.bind(CurrentChar))
	#Portrait.texture = Char.CharacterPortrait
	#Char.RecoveryPunished.connect(RecoveryPunished)
	
	if (!DoAtackAnimations):
		return
	var MaxHP = Char.GetStat(CharacterStat.STATS.MAX_HP)
	var CurrentHP = Char.CurrentHP
	CharacterHealthBar.max_value = MaxHP
	CharacterHealthBar.value = CurrentHP
	CharacterHealthLabel.text = "{0}/{1}".format([roundi(CurrentHP), roundi(MaxHP)])
	
	var MaxStamina = Char.GetMaxFatigue()
	var CurrentStamina = Char.GetMaxFatigue() - Char.Fatigue
	CharacterStaminaBar.max_value = MaxStamina
	CharacterStaminaBar.value = CurrentStamina
	CharacterStaminaLabel.text = "{0}/{1}".format([roundi(CurrentStamina), roundi(MaxStamina)])
	
	var MaxMana = Char.GetStat(CharacterStat.STATS.MAX_MANA)
	var CurrentMana = Char.CurrentMana
	CharacterManaBar.visible = MaxMana > 0
	CharacterManaText.visible = MaxMana > 0
	CharacterManaBar.max_value = MaxMana
	CharacterManaBar.value = CurrentMana
	CharacterManaLabel.text = "{0}/{1}".format([roundi(CurrentMana), roundi(MaxMana)])
	

func RecoveryPunished() -> void:
	return
	#if (!DoAtackAnimations):
		#return
	#var f = Floater.new()
	#f.text = "-Recovery Time"
	#f.SetColor(false)
	#FloaterParent.add_child(f)
	##f.PositionToSpawn = global_position + size/2
	#f.add_theme_font_size_override("font_size", 24)

func RemoveCharacter() -> void:
	#CurrentChar.LevelChanged.disconnect(LevelGained)
	#CurrentChar.ExpGained.disconnect(StatsUpdated.bind(CurrentChar))
	CurrentChar.Damaged.disconnect(CharacterDamaged.bind(CurrentChar))
	CurrentChar.Killed.disconnect(CharacterKilled)
	CurrentChar.Healed.disconnect(Healed.bind(CurrentChar))
	CurrentChar.Picked.disconnect(CharacterPicked)
	CurrentChar.FatigueHealed.disconnect(FatigueHealed.bind(CurrentChar))
	CurrentChar.FatigueDamaged.disconnect(FatigueDamaged.bind(CurrentChar))
	CurrentChar.RecoveryPunished.disconnect(RecoveryPunished)
	CurrentChar = null

func CharacterPicked(t : bool) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	if (t):
		tw.tween_property(self, "position", Vector2(position.x, position.y - 20), 0.15)
	else:
		tw.tween_property(self, "position", Vector2(position.x, position.y + 20), 0.15)

func AtackProcessed(_TimeLeft : float) -> void:
	#AtackBar.value = TimeLeft
	pass

func CharacterKilled() -> void:
	DeathPanel.visible = true

func FatigueHealed(_Amm : int, Char : Character) -> void:
	alpha = 10.0
	StatsUpdated(Char)
	return
	#if (!DoAtackAnimations):
		#return
	#var f = Floater.new()
	#f.text = "-{0} Fatigue".format([Amm])
	#FloaterParent.add_child(f)
	##f.PositionToSpawn = global_position + size/2
	#f.add_theme_font_size_override("font_size", 24)
	##var tw = create_tween()
	##tw.set_ease(Tween.EASE_OUT)
	##tw.set_trans(Tween.TRANS_BACK)
	##tw.tween_property(self, "modulate", Color(0.0, 0.836, 0.088, 1.0), 0.15)
	##await tw.finished
	##var tw2 = create_tween()
	##tw2.set_ease(Tween.EASE_OUT)
	##tw2.set_trans(Tween.TRANS_BACK)
	##tw2.tween_property(self, "modulate", Color(1,1,1), 0.15)
	#
	#AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, -15)

func FatigueDamaged(_Amm : int, Char : Character) -> void:
	alpha = 10.0
	StatsUpdated(Char)
	if (!DoAtackAnimations):
		return
	#var f = Floater.new()
	#f.text = "+{0} Fatigue".format([Amm])
	#FloaterParent.add_child(f)
	##f.PositionToSpawn = global_position + size/2
	#f.add_theme_font_size_override("font_size", 24)
	
	if (Char.Exposure > 0):
		var f2 = Floater.new()
		f2.text = "STUNNED"
		FloaterParent.add_child(f2)
		f2.add_theme_font_size_override("font_size", 24)
		
		StunnTex.visible = true
		
		var tw = create_tween()
		tw.tween_property(StunnTex, "rotation", PI * 4, 2)
		await tw.finished
		StunnTex.visible = false
		StunnTex.rotation = 0
		#f2.PositionToSpawn = global_position + size/2
	#var tw = create_tween()
	#tw.set_ease(Tween.EASE_OUT)
	#tw.set_trans(Tween.TRANS_BACK)
	#tw.tween_property(self, "modulate", Color(0.901, 0.201, 0.0, 1.0), 0.15)
	#await tw.finished
	#var tw2 = create_tween()
	#tw2.set_ease(Tween.EASE_OUT)
	#tw2.set_trans(Tween.TRANS_BACK)
	#tw2.tween_property(self, "modulate", Color(1,1,1), 0.15)

func Healed(_Amm : int, Char : Character) -> void:
	DeathPanel.visible = false
	alpha = 10.0
	StatsUpdated(Char)
	return
	#if (!DoAtackAnimations):
		#return
	#var f = Floater.new()
	#f.text = "+{0} HP".format([Amm])
	#FloaterParent.add_child(f)
	##f.PositionToSpawn = global_position + size/2
	#f.SetColor(true)
	#f.add_theme_font_size_override("font_size", 24)
	#var tw = create_tween()
	#tw.set_ease(Tween.EASE_OUT)
	#tw.set_trans(Tween.TRANS_BACK)
	#tw.tween_property(self, "modulate", Color(0.0, 0.836, 0.088, 1.0), 0.15)
	#await tw.finished
	#var tw2 = create_tween()
	#tw2.set_ease(Tween.EASE_OUT)
	#tw2.set_trans(Tween.TRANS_BACK)
	#tw2.tween_property(self, "modulate", Color(1,1,1), 0.15)
	#
	#AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, -15)

func CharacterDamaged(_OriginalDamage : int, _FinalDamage : int, _Instigator : Actor, Char : Character) -> void:
	StatsUpdated(Char)
	alpha = 10.0
	if (DoAtackAnimations):
		#var f = Floater.new()
		#f.text = "-{0} HP".format([FinalDamage])
		#FloaterParent.add_child(f)
		##f.PositionToSpawn = global_position + size/2
		#f.SetColor(false)
		#f.add_theme_font_size_override("font_size", 24)
		
		var slash = SlashAnim.instantiate() as AnimatedSprite2D
		add_child(slash)
		slash.animation_finished.connect(slash.queue_free)
		slash.play()
		slash.position = size / 2
		
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "modulate", Color(1.0, 0.539, 0.475, 1.0), 0.15)
		await tw.finished
		var tw2 = create_tween()
		tw2.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_BACK)
		tw2.tween_property(self, "modulate", Color(1,1,1), 0.15)
	
		
	
	

func Atacked(_Damage : int) -> void:
	return
	#if (DoAtackAnimations):
		#var tw = create_tween()
		#tw.set_ease(Tween.EASE_OUT)
		#tw.set_trans(Tween.TRANS_BACK)
		#tw.tween_property(self, "position", Vector2(position.x, position.y - 20), 0.15)
		#await tw.finished
		#var tw2 = create_tween()
		#tw2.set_ease(Tween.EASE_OUT)
		#tw2.set_trans(Tween.TRANS_BACK)
		#tw2.tween_property(self, "position", Vector2(position.x, position.y + 20), 0.15)

#func LevelGained() -> void:
	#if (DoAtackAnimations):
		#var f = Floater.new()
		#f.text = "Level Up"
		##f.Reverse = true
		#FloaterParent.add_child(f)
		##f.PositionToSpawn = global_position + size/2
		#f.add_theme_font_size_override("font_size", 24)
		#AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, -5)
		#StatsUpdated(CurrentChar)
		#LevelText.text = var_to_str(CurrentChar.CharacterLevel)

func StatsUpdated(Char : Character) -> void:
	
	if (CharacterStatLabel != null):
		var stattext : String = ""
		for g in CharacterStat.STATS.values():
			stattext += "[img={16}x{16}]{0}[/img]|{1}".format([CharacterStat.GetIconForStat(g), Char.GetStat(g)])
			if (g < CharacterStat.STATS.keys().size() - 1):
				stattext += "\n"
				
		CharacterStatLabel.text = stattext
	if (!DoAtackAnimations):
		return
		
	var MaxHP = roundi(Char.GetStat(CharacterStat.STATS.MAX_HP))
	var CurrentHP = roundi(Char.CurrentHP)
	CharacterHealthBar.max_value = MaxHP
	CharacterHealthBar2.max_value = MaxHP
	CharacterHealthLabel.text = "{0}/{1}".format([CurrentHP, MaxHP])
	SetHealthValue(CurrentHP)
	if (CurrentHP <= 10):
		CharacterHealthBar.modulate = Color(1.0, 0.379, 0.311, 1.0)
	else:
		CharacterHealthBar.modulate = Color(1,1,1)
		
	var MaxStamina = roundi(Char.GetMaxFatigue())
	var CurrentStamina = roundi(Char.GetMaxFatigue() - Char.Fatigue)
	CharacterStaminaBar.max_value = MaxStamina
	CharacterStaminaBar2.max_value = MaxStamina
	CharacterStaminaLabel.text = "{0}/{1}".format([CurrentStamina, MaxStamina])
	SetStaminaValue(CurrentStamina)
	if (CurrentStamina <= 10):
		CharacterStaminaLabel.modulate = Color(1.0, 0.379, 0.311, 1.0)
	else:
		CharacterStaminaLabel.modulate = Color(1,1,1)
	
	var MaxMana = Char.GetStat(CharacterStat.STATS.MAX_MANA)
	var CurrentMana = Char.CurrentMana
	CharacterManaBar.visible = MaxMana > 0
	CharacterManaText.visible = MaxMana > 0
	CharacterManaBar.max_value = MaxMana
	CharacterManaBar2.max_value = MaxMana
	SetManaValue(CurrentMana)
	CharacterManaLabel.text = "{0}/{1}".format([roundi(CurrentMana), roundi(MaxMana)])

func SetHealthValue(Value : float) -> void:
	if (CharacterHealthBar.value == Value):
		return
	if (is_instance_valid(HealthTween)):
			HealthTween.kill()
	HealthTween = create_tween()
	HealthTween.set_trans(Tween.TRANS_BACK)
	HealthTween.set_ease(Tween.EASE_OUT)
	if (CharacterHealthBar.value > Value):
		var PrevValue = CharacterHealthBar.value
		CharacterHealthBar2.value = PrevValue
		HealthTween.tween_property(CharacterHealthBar2, "value", Value, 0.5)
		CharacterHealthBar.value = Value
	else:
		CharacterHealthBar2.value = Value
		HealthTween.tween_property(CharacterHealthBar, "value", Value, 0.5)

func SetStaminaValue(Value : float) -> void:
	if (CharacterStaminaBar.value == Value):
		return
	if (is_instance_valid(StaminaTween)):
		StaminaTween.kill()
	StaminaTween= create_tween()
	StaminaTween.set_trans(Tween.TRANS_BACK)
	StaminaTween.set_ease(Tween.EASE_OUT)
	if (CharacterStaminaBar.value > Value):
		var PrevValue = CharacterStaminaBar.value
		CharacterStaminaBar2.value = PrevValue
		StaminaTween.tween_property(CharacterStaminaBar2, "value", Value, 0.5)
		CharacterStaminaBar.value = Value
	else:
		CharacterStaminaBar2.value = Value
		StaminaTween.tween_property(CharacterStaminaBar, "value", Value, 0.5)

func SetManaValue(Value : float) -> void:
	if (CharacterManaBar.value == Value):
		return
	if (is_instance_valid(ManaTween)):
		ManaTween.kill()
	ManaTween= create_tween()
	ManaTween.set_trans(Tween.TRANS_BACK)
	ManaTween.set_ease(Tween.EASE_OUT)
	if (CharacterManaBar.value > Value):
		var PrevValue = CharacterManaBar.value
		CharacterManaBar2.value = PrevValue
		ManaTween.tween_property(CharacterManaBar2, "value", Value, 0.5)
		CharacterManaBar.value = Value
	else:
		CharacterManaBar2.value = Value
		ManaTween.tween_property(CharacterManaBar, "value", Value, 0.5)

func _on_mouse_entered() -> void:
	CharacterStatLabel.visible = true


func _on_mouse_exited() -> void:
	CharacterStatLabel.visible = false
