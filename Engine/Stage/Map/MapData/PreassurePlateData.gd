@tool
extends Resource

class_name PreassuerPlateData

@export var Info : PreassurePlateCallInfo
@export var State : bool = false


enum SwitchElement{
	NORMAL = 0,
	FIRE = 1,
	ICE = 2,
}
