@tool
extends Resource

class_name CellData

enum CELLTYPE{
	NORMAL,
	WATER,
	LAVA,
	GAP,
	FALL,
	DOWN_LADDER,
	UP_LADDER,
	DOWN_STAIRS,
	UP_STAIRS,
	BONEFIRE,
	DUGGABLE,
	DUG_DUGGABLE,
	ENDPOINT,
	EXIT,
}

@export var type : CELLTYPE

@export var spawnFloor : bool
@export var spawnCeiling : bool
@export var floorAsCeiling : bool
@export var CrackedFloor : bool = false
@export var CrackedCeiling : bool = false

@export var Custom_Data : Dictionary

@export var stressLevel : int = 0
@export var Text : DialogueContainer

func AddData(dataName : String, data : Variant) -> void:
	Custom_Data[dataName] = data

func AddDataArr(dataName : String, data : Variant) -> void:
	if (!Custom_Data.has(dataName)):
		Custom_Data[dataName] = []

	Custom_Data[dataName].append(data)

func HasData(dataName : String) -> bool:
	if (!Custom_Data.has(dataName)):
		return false
	
	if (Custom_Data[dataName] is Array):

		if (Custom_Data[dataName].size() == 0):
			return false
		
	return true
