@tool
extends Node3D

class_name TrapManager

#@export_group("Trap_Settings")
@export var TrapSetting : Array[TrapSettings]
@export var TrapScenes : Dictionary[Map.TrapType, PackedScene]
var Traps : Dictionary[Vector3i, TrapData]

var SpawnedTraps : Array[BaseTrap]

func PlPositionChanged(Data : MapData, positions : Array[Vector3i]) -> void:
	for trapIndex in range(Traps.size() - 1, -1, -1):
		var pos = Traps.keys()[trapIndex]
		if (!positions.has(pos)):
			Traps.erase(pos)
	for mapPos in positions:
		if (Traps.has(mapPos)):
			continue
		var cell = Data.cells[mapPos]
		if (cell.HasData("Trap")):
			var trap : MapTrapData = cell.Custom_Data["Trap"]
			AddTrap(mapPos, trap.TrapTransform, trap.TrapType)

func GetTrapSetting(Type : Map.TrapType) -> TrapSettings:
	var Setting : TrapSettings
	for g in TrapSetting:
		if (g.TrapType == Type):
			Setting = g
			break
	
	return Setting

func Toggle(t) -> void:
	set_physics_process(t)
	for g in SpawnedTraps:
		g.Toggle(t)

func Update(delta: float) -> void:
	for g in SpawnedTraps:
		g.Update(delta)
	for g in Traps.values():
		var Loc = g.Location
		#if (PlayerPos.distance_squared_to(Loc.origin) > 500 or PlayerPos.y != Loc.origin.y + 1):
			#continue

		g.Cooldown -= delta
		if (g.Cooldown <= 0):
			var Setting = GetTrapSetting(g.TrapType)
			g.Cooldown = Setting.Cooldown
			var Trap : Node3D = TrapScenes[g.TrapType].instantiate()
			
			Trap.transform = Loc
			Trap.Speed = Setting.CustomData["Speed"]
			SpawnedTraps.append(Trap)
			Trap.Killed.connect(TrapDestroyed.bind(Trap))
			
			if (g.TrapType == Map.TrapType.FIRE_TRAP):
				Trap.position -= Vector3.LEFT.rotated(Vector3(0,1,0), Trap.rotation.y) * 0.6
				Trap.rotation.y -= PI/2
				Trap.ProjectileRange = Setting.CustomData["Range"]
			if (g.TrapType == Map.TrapType.FIREPIT_TRAP):
				Trap.Lifetime = Setting.CustomData["Lifetime"]
			add_child(Trap)

func TrapDestroyed(t : BaseTrap) -> void:
	SpawnedTraps.erase(t)

func AddCustom(Location : Transform3D, Trap : BaseTrap) -> void:
	SpawnedTraps.append(Trap)
	add_child(Trap)
	Trap.Killed.connect(TrapDestroyed.bind(Trap))
	Trap.transform = Location

func PurgeTraps() -> void:
	Traps.clear()

func AddTrap(mapPos : Vector3i,Location : Transform3D, Type : Map.TrapType) -> void:
	var Trap = TrapData.new()
	Trap.Location = Location
	Trap.TrapType = Type
	Trap.Cooldown = GetTrapSetting(Type).Cooldown
	Traps[mapPos] = Trap
