extends Resource

class_name Weapon

@export_range(0.0, 1.5) var Speed : float = 1.0
@export_range(10, 100) var Stamina_Cost : float = 10.0
@export var Damage : float = 1.0
@export var WeaponType : Fight_Animation_Modifier.WeaponType
@export var Pierce : bool = false
@export var WeaponScene : PackedScene
@export var Proj : Projectile
@export var WeaponClashSound : AudioManager.Sound = AudioManager.Sound.SWORD_CLASH

var Equipped : bool = false

signal OnWeaponEquiped(t : bool)

const WEAPON_MIN_SPEED : float = 0.8
const WEAPON_MAX_SPEED : float = 1.5

func WeaponEquiped(t : bool) -> void:
	Equipped = t
	OnWeaponEquiped.emit(t)
