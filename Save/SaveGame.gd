extends Resource

class_name Save

@export var WorldData : Dictionary[Map.LocationName, MapData]
@export var PlayerLocation : Vector3i
@export var PlayerCharacter : Character
@export var InventoryContents : Array[Item]
@export var CurrentWorld : Map.LocationName
@export var GameVersion : String
@export var MiniData : Dictionary[Map.LocationName, MinimapData]
@export var CurrentStress : float
@export var CurrentCurrency : int
@export var Globals : Dictionary[Global_Manager.GlobalNames, Variant]
