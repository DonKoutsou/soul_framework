@tool
extends LeverCallInfo

class_name GlobalLeverCallInfo

@export var UseColor : bool = false
@export var PrimaryGlobal : Global_Manager.GlobalNames
@export var SecondaryGlobals : Array[Global_Manager.GlobalNames]

func SetGlobals(t : bool) -> void:
	Global_Manager.SetGlobal(PrimaryGlobal, t)
	for g in SecondaryGlobals:
		Global_Manager.SetGlobal(g, false)
