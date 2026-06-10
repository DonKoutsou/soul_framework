extends Node

class_name Global_Manager

static var DefaultGlobals : Dictionary[GlobalNames, Variant] = {GlobalNames.Test1: false,}
static var Globals : Dictionary[GlobalNames, Variant]

func _ready() -> void:
	ResetGlobals()

func _exit_tree() -> void:
	ResetGlobals()

func ResetGlobals() -> void:
	Globals = DefaultGlobals.duplicate()

static func GetGlobal(Name : GlobalNames) -> Variant:
	return Globals[Name]

static func SetGlobal(Name : GlobalNames, NewValue : Variant) -> void:
	Globals[Name] = NewValue

static func ToggleGlobal(Name : GlobalNames) -> void:
	Globals[Name] = !Globals[Name]

enum GlobalNames{
	Test1,
}

static func GetGlobalColor(Global : GlobalNames) -> Color:
	match(Global):
		GlobalNames.Test1:
			return Color(1,0,0)
	return Color(1,1,1)
