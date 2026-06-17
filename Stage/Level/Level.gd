@tool
extends Node3D

class_name Level

@export_group("Managers")
@export var MonsterMan : MonsterManager
@export var TrapMan : TrapManager
@export var AudioMan : LevelEnviromentSoundManager
@export var AmbientAudio : AudioStreamPlayer
@export var WallCollider : Mesh
@export_group("MuliMeshes")
@export var PropMeshSpawner : MeshSpawner
@export var BackgroundMesh : MeshInstance3D
@export var ProjectileSwitchArea : Area3D
@export_group("Scenes")
@export var RecruitScene : PackedScene
@export var EnemyManequinScene : PackedScene
@export var BarrelBreakParticles : PackedScene
@export var WallBreakParticles : PackedScene
@export var FloorBreakParticles : PackedScene

@export var ParticlePack : PackedScene
@export var DialogueTriggerScene : PackedScene
@export_group("Settings")
@export var StepSound : AudioManager.Sound = AudioManager.Sound.STEP
@export var WalkSound : AudioManager.Sound = AudioManager.Sound.WALK
@export var LoadDistance : int = 3

static var CurrentWorldScale : Vector3i = Vector3i(1,1,1)
static var CurrentWallCollider : Mesh
static var EnemyOccupiedSlots : PackedVector3Array

var SpawnPoint : Vector3
var SpawnRotation : float

var builderThreadTaskID : int = -1

var Characters : Dictionary[Vector3i, MapCharacter]

var MData : Map

signal GenerationFinished
signal EnemyMet(Group : MonsterGroup)
signal ProjectileSwitchPressed(Index : ProjectileSwitchData, Element : ProjectileSwitchData.SwitchElement, PlayerSpawned : bool)

var Paused : bool = false

var MultiMeshes : Dictionary[LevelMultimesh.LevelMultimeshTypes ,LevelMultimesh]
var MultiLayerMultiMeshes : Dictionary[LevelMultimesh.LevelMultimeshTypes ,LevelMultiLayerMultimesh]

var Positions : Array[Vector3i]

var QueuedToUpdate : Array[LevelMultimesh.LevelMultimeshTypes]
var QueuedUpdate : bool = false

func _enter_tree() -> void:
	CurrentWallCollider = WallCollider

func _ready() -> void:
	call_deferred("StoreMultiMeshes")
	call_deferred("SetBG")
	if (Engine.is_editor_hint()):
		return
	MonsterMan.MonsterMetPlayer.connect(MonsterMetPlayer)
	MonsterMan.SetLoadDist(LoadDistance)


func SetBG() -> void:
	BackgroundMesh.scale = (CurrentWorldScale * LoadDistance) * 2

func StoreMultiMeshes() -> void:
	MultiMeshes.clear()
	MultiLayerMultiMeshes.clear()
	print("Strarted storing meshes")
	for g in get_children():
		if (g is LevelMultimesh):
			MultiMeshes[g.GetLayerType()] = g
		else: if (g is LevelMultiLayerMultimesh):
			MultiLayerMultiMeshes[g.GetLayerType()] = g

func GetMapData() -> MapData:
	return MData.Data

func Update(delta: float) -> void:
	if (QueuedUpdate):
		UpdateMultiMeshes()
		QueuedUpdate = false
	#if (Engine.is_editor_hint()):
		#return
	if (!Paused):
		MonsterMan.Update(delta)
		TrapMan.Update(delta)
		for g in Characters:
			var rec = Characters[g]
			rec.Update(delta)
		for g : LevelMultimesh in MultiMeshes.values():
			g.Proc(delta)
		for g : LevelMultiLayerMultimesh in MultiLayerMultiMeshes.values():
			g.Proc(delta)
	
func PauseLevel(t : bool) -> void:
	Paused = t

func configure_map(M : Map) ->void:
	MData = M
	add_child(MData)
	CurrentWorldScale = MData.WorldScale
	
	PropMeshSpawner.SpawnMeshes(M.Props)
	AudioMan.Data = MData

func PlayerPositionChanged(Pos : Vector3, Rot : Vector3) -> void:
	PropMeshSpawner.PlayerPositionChanged(Pos, Rot)
	
	QueuedToUpdate.clear()
	QueuedToUpdate.append_array(LevelMultimesh.LevelMultimeshTypes.values())
	QueuedUpdate = true
	if (Engine.is_editor_hint()):
		Positions = GetMapData().get_points_in_square(Helper.PlayerPositionToMap(Pos), LoadDistance)
		BackgroundMesh.position = Pos * Vector3(1,0,1)
		TrapMan.PlPositionChanged(GetMapData(), Positions)
		return
	
	Positions = GetMapData().get_points_in_square(Helper.PlayerPositionToMap(Pos), LoadDistance)
	
	var tw = create_tween()
	tw.tween_property(BackgroundMesh, "position", Pos - Vector3(0, 1, 0), 0.6)
	
	TrapMan.PlPositionChanged(GetMapData(), Positions)
	MonsterMan.PlPositionChanged(Pos)

func MonsterMetPlayer(Group : MonsterGroup) -> void:
	EnemyMet.emit(Group)

func RedoMap(SpawnMonsters : bool = true) -> void:
	print("Redoing map with 'Spawn Monsters set to {0}'".format([SpawnMonsters]))
	TrapMan.PurgeTraps()
	
	PropMeshSpawner.ClearMeshes()
	PropMeshSpawner.SpawnMeshes(MData.Props)
	
	for g : LevelMultimesh in MultiMeshes.values():
		g.Clear()
	
	StartBuildingThread(SpawnMonsters)

func StartBuildingThread(SpawnMonsters : bool = true) -> void:
	builderThreadTaskID = WorkerThreadPool.add_task(BuildMaze.bind(SpawnMonsters))

func BuildingFinished() -> void:
	WorkerThreadPool.wait_for_task_completion(builderThreadTaskID)
	builderThreadTaskID = -1
	
func NotifyFinished() -> void:
	GenerationFinished.emit()
	call_deferred("ApplyGlobals")
	call_deferred("ApplyGlobalLevers")
	
func ApplyGlobalLevers() -> void:
	for mapPos : Vector3i in GetMapData().cells:
		var cell = GetMapData().GetCell(mapPos)
		if (!cell.Custom_Data.has("Lever")):
			continue
		var LData = cell.Custom_Data["Lever"]
		var LeverInfo = LData.Info
		if (LeverInfo is GlobalLeverCallInfo):
			var LeverState : bool = LData.State
	
			var GlobalValue = Global_Manager.GetGlobal(LeverInfo.PrimaryGlobal)
			if (GlobalValue == LeverState):
				FlipSwitch(mapPos)
				LData.State = !GlobalValue
	QueuedUpdate = true
	
func ApplyGlobals() -> void:
	for Info in MData.GlobalCatalogue:
		var DoorPos = Info.DoorLoc
		var cell = GetMapData().GetCell(DoorPos)
		var doorDat : DoorData = cell.Custom_Data["Door"]
		#var OppositeDoorPos = doorDat.OpossiteDoorMapPosition
		var T = Global_Manager.GetGlobal(Info.GlobalDependancy)
		
		var IsLocked = doorDat.DoorState
		
		if (IsLocked == T):
			continue
		ToggleDoor(DoorPos)
	
	QueuedUpdate = true

#MAZE GENERATION
func BuildMaze(SpawnMonsters : bool) -> void:
	var Data = MData.Data
	var SpawnP = Data.SpawnPoint as Vector3i

	SpawnPoint = Helper.MapToPlayerPosition(SpawnP)
	
	if (SpawnMonsters):
		for z in GetMapData().cells:
			var cell = GetMapData().GetCell(z)
			if (!cell.HasData("MonsterSpawn")):
				continue
		#for g :MonsterHouse in MData.Data.MonsterHouses:
			var m = EnemyManequinScene.instantiate() as EnemyManequin
			var monHouse : MonsterGroup = cell.Custom_Data["MonsterSpawn"]
			m.G = monHouse
			m.CurrentPosition = monHouse.OriginalPos
			if (monHouse.LastKnownPosition != Vector3i.ZERO):
				m.CurrentPosition = Helper.PlayerPositionToMap(monHouse.LastKnownPosition)
			
			#monHouse.RegisterGroups()
			
			MonsterMan.call_deferred("AddMonster", m)
			if (!monHouse.IsAlive()):
				m.call_deferred("Dead")

	call_deferred("NotifyFinished")
	call_deferred("BuildingFinished")


func UpdateMultiMeshes() -> void:
	var r = GetMapData().GetRandomGenerator()
	
	for g : LevelMultimesh in MultiMeshes.values():
		if (QueuedToUpdate.has(g.GetLayerType())):
			QueuedToUpdate.erase(g.GetLayerType())
			g.Update(GetMapData(), Positions, r)

	for g : LevelMultiLayerMultimesh in MultiLayerMultiMeshes.values():
		g.Update(GetMapData(), Positions, r)

	UpdateMapCharacters()

func RemoveFrom(layer : LevelMultimesh.LevelMultimeshTypes, removeLocations : Array[Vector3i]) -> void:
	for pos : Vector3i in removeLocations:
		MultiMeshes[layer].RemoveSpot(GetMapData(), pos)
	QueuedToUpdate.append(layer)
	QueuedUpdate = true

func AddTo(layer : LevelMultimesh.LevelMultimeshTypes, addLocatiaon : Array[Vector3i]) -> void:
	for pos :  Vector3i in addLocatiaon:
		MultiMeshes[layer].AddSpot(GetMapData() ,pos)
	QueuedToUpdate.append(layer)
	QueuedUpdate = true

func AddHazard(Pos : Vector3i) -> void:
	var Floor = MData.GetFloor(Pos.y)
	var Index = Floor.GetLayer(FloorLayer.LayerType.MAP_INFO).get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x
	match (Index):
		16:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.WATER].AddSpot(GetMapData(), Pos)
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.WATER)
		22:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.LAVA].AddSpot(GetMapData(), Pos)
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.LAVA)
		23:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.GAP].AddSpot(GetMapData(), Pos)
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.GAP)
	QueuedUpdate = true

func RemoveHazard(Pos : Vector3i) -> void:
	var cell = GetMapData().cells[Pos]
	
	match (cell.type):
		CellData.CELLTYPE.WATER:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.WATER].RemoveSpot(GetMapData(), Pos)
			cell.type = CellData.CELLTYPE.NORMAL
			cell.spawnFloor = true
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.WATER)
		CellData.CELLTYPE.LAVA:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.LAVA].RemoveSpot(GetMapData(), Pos)
			cell.type = CellData.CELLTYPE.NORMAL
			cell.spawnFloor = true
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.LAVA)
		CellData.CELLTYPE.GAP:
			MultiMeshes[LevelMultimesh.LevelMultimeshTypes.GAP].RemoveSpot(GetMapData(), Pos)
			cell.type = CellData.CELLTYPE.NORMAL
			cell.spawnFloor = true
			QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.GAP)
	
	QueuedUpdate = true

func ToggleDoor(Pos : Vector3i) -> void:
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.DOORS].ToggleDoor(GetMapData(), Pos)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.DOORS)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.LOCKS)
	QueuedUpdate = true

func FlipSwitch(Pos : Vector3i) -> void:
	var cell = GetMapData().GetCell(Pos)
	var leverData : LeverData = cell.Custom_Data["Lever"]
	var LeverTrans = leverData.Trans
	leverData.Trans = LeverTrans.rotated_local(Vector3i(1,0,0), PI)
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.LEVERS].RemoveSpot(GetMapData(), Pos)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.LEVERS)
	QueuedUpdate = true

func BreakFloor(Pos : Vector3i) -> void:
	var cell = GetMapData().cells[Pos]
	
	var bellowPos = Vector3i(Pos.x, Pos.y - 1, Pos.z)
	var bellowcell = GetMapData().cells[bellowPos]
	
	cell.type = CellData.CELLTYPE.FALL
	cell.spawnFloor = false
	bellowcell.spawnCeiling = false
	
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.FLOOR].RemoveSpot(GetMapData(), Pos)
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.CEILING].RemoveSpot(GetMapData(), bellowPos)
	
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.FLOOR)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.CEILING)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.FALL)
	
	QueuedUpdate = true
	
func BreakWall(Pos : Vector3i, crackedWall : WallData, lookingPos : Vector3i, lookingCrackedWall : WallData) -> void:
	var Data = GetMapData()
	var cell : CellData = Data.cells[Pos]
	var lookingcell : CellData = Data.cells[lookingPos]
	
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.WALLS].RemoveIndex(GetMapData(), Pos, cell.Custom_Data["Walls"].find(crackedWall))
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.WALLS].RemoveIndex(GetMapData(), lookingPos, lookingcell.Custom_Data["Walls"].find(lookingCrackedWall))
	
	cell.AddDataArr("BrokenWalls", crackedWall.WallTransform)
	
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.WALLS)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.BROKEN_WALLS)
	
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.WALLS)
	QueuedToUpdate.append(LevelMultimesh.LevelMultimeshTypes.BROKEN_WALLS)

	QueuedUpdate = true

func SpawnPlayer(Pl : BasePlayerManequin) -> void:
	add_child(Pl)
	#Pl.call_deferred("Teleport", SpawnPoint)
	BackgroundMesh.position = SpawnPoint
	Pl.Teleport(SpawnPoint)
	Pl.SetLookDir(GetMapData().SpawnRot)
	
	var Part = ParticlePack.instantiate()
	Pl.add_child(Part)
	Part.position.y += 1

func UpdateMapCharacters() -> void:
	#Removal of old recruits
	for recruitIndex in range(Characters.size() - 1, -1, -1):
		var recruitPos = Characters.keys()[recruitIndex]
		if (!Positions.has(recruitPos)):
			Characters[recruitPos].queue_free()
			Characters.erase(recruitPos)
	
	for mapPos in Positions:
		if (Characters.has(mapPos)):
			continue
		var cell = MData.Data.cells[mapPos]
		if (cell.HasData("Recruit")):
			var realPos = Helper.MapToPlayerPosition(mapPos)
			
			var Rec = RecruitScene.instantiate() as MapCharacter
			Rec.ConfigureCharacter(cell.Custom_Data["Recruit"])
			
			Characters[mapPos] = Rec
			Rec.position = Vector3(realPos) + Vector3(0, 0.1 ,0)
			
			call_deferred("add_child", Rec)

func UpdatePlate(pos : Vector3i) -> void:
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.PLATES].UpdatePlate(GetMapData(), pos)

func UpdateProjectileSwitch(pos : Vector3i) -> void:
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.PROJECT_SWITCHES].UpdateSwitch(GetMapData(), pos)

func UpdateMovable(pos : Vector3i) -> void:
	MultiMeshes[LevelMultimesh.LevelMultimeshTypes.MOVABLES].UpdateMovable(GetMapData(), pos)

func ToggleAmbientSound(t : bool) -> void:
	AmbientAudio.playing = t

func _on_projectile_switch_collision_area_shape_entered(_area_rid: RID, area: Area3D, _area_shape_index: int, local_shape_index: int) -> void:
	var Parent = area.get_parent()
	if (Parent is BaseTrap):
		var own = ProjectileSwitchArea.shape_find_owner(local_shape_index)
		var collision : ProjectileSwitchCollision = ProjectileSwitchArea.shape_owner_get_owner(own)
		var dat = collision.SwitchInfo
		ProjectileSwitchPressed.emit(dat, Parent.Element, Parent.PlayerSpawned)
