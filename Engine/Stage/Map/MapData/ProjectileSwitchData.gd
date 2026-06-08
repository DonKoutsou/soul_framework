@tool
extends Resource

class_name ProjectileSwitchData

@export var Info : ProjectileSwitchCallInfo
@export var Pos : Vector3i
@export var State : bool = false


enum SwitchElement{
	NORMAL = 0,
	FIRE = 1,
	ICE = 2,
}
