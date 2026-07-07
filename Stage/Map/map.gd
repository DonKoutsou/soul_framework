@tool
extends Node2D

#Used to configure the map in editor.
class_name Map

@export var LevelName : LocationName

@export_group("Settings")
@export var SpawnMonsters : bool = true
@export var SpawnBackWalls : bool = true
@export var RandomSeed : int = 10
@export var DecorationProbability : int = 100
@export_file("*.tscn") var levelScene : String = "res://Engine/Stage/Level/BaseLevel.tscn"
@export var WorldScale : Vector3i = Vector3i(2,2,2)

@export_group("Nodes")
@export var Floors : Array[FloorLayer]

@export_group("Catalogues")
@export var LevelTransitionCatalogue : Array[LocationName]
@export var TextCatalogue : Array[DialogueContainer]
@export var GlobalCatalogue : Array[GlobalDoorInfo]
@export var LeverCatalogue : Array[SwitchCallInfo]
@export var LockCatalogue : Array[Item]
@export var MovableCatalogue : Array[MovableSwitchCallInfo]
@export var PlateCatalogue : Array[PreassurePlateCallInfo]
@export var ProjectileSwitchCatalogue : Array[ProjectileSwitchCallInfo]
@export_file("*.tres") var ItemCaralogue : Array[String]
@export_file("*.tres") var MonsterCatalogue : Array[String]
@export_file("*.tres") var CharacterCatalogue : Array[String]

@export_group("Prop Configuration")
#Array of Transform3D
@export var Props : Dictionary[Mesh, Array]
@export var MegaProps : Dictionary[Mesh, Array]


var Data : MapData
var AccumulatedHours : int

var generationThreadTaskID : int = -1
signal GenerationFinished

enum LocationName{
	Base,
	Forest,
	Underground_Jail,
	Abandoned_House1,
	Abandoned_House2,
	Abandoned_House3,
	Goblin_Infested_Cave,
	Dungeon,
	Test_Map,
	Cave,
	Graveyard,
	Graveyard_House,
	Cave_Forest_Path,
	Jail_Entrance,
	Canyon,
	Artifex,
	Chalice,
	Artifex_Exterior,
}

enum TrapType {
	SPIKE_TRAP,
	FIRE_TRAP,
	GUILOTINE_TRAP,
	FIREPIT_TRAP
}

func GetFloorAmm() -> int:
	return Floors.size()

func HasFLoor(FloorIndex : int) -> bool:
	for g : FloorLayer in Floors:
		if (g.FloorNumber == FloorIndex):
			return true
	return false

func GetFloor(FloorIndex : int) -> FloorLayer:
	for g : FloorLayer in Floors:
		if (g.FloorNumber == FloorIndex):
			return g
	return null

var editorCamPos : Vector3i

func _ready() -> void:
	if (Engine.is_editor_hint()):
		return
	else:
		set_physics_process(false)

	visible = false

## check is cell is a lava tile
func IsWater(Pos : Vector3i) -> bool:
	if (!Data.cells.has(Pos)):
		return false
	return Data.cells[Pos].type == CellData.CELLTYPE.WATER

## check is cell is a water tile
func IsLava(Pos : Vector3i) -> bool:
	if (!Data.cells.has(Pos)):
		return false
	return Data.cells[Pos].type == CellData.CELLTYPE.LAVA

## Used when we want to pass, reaspawns monsters
func TimePassed(T : int) -> void:
	AccumulatedHours += T
	
	var RespawnTokens : int = roundi(AccumulatedHours / 6.0)
	
	if (RespawnTokens == 0):
		return
	
	for g in RespawnTokens:
		AccumulatedHours -= 6
	
	for z in Data.cells:
		var cell = Data.cells[z]
		if (cell.HasData("MonsterSpawn")):
			cell.Custom_Data["MonsterSpawn"].Respawn(RespawnTokens)


func GetMonsterHouseForPosition(Pos : Vector3i) -> MonsterGroup:
	var MonsterActorOnPosition : MonsterGroup
	var NormalPos = Vector2i(Pos.x, Pos.z)
	
	for g in Data.cells:
		var cell = Data.cells[g]
		if (!cell.HasData("MonsterSpawn")):
			continue
		var monsterActor = cell.Custom_Data["MonsterSpawn"]

		if (monsterActor.OriginalPos.y == Pos.y and monsterActor.Tiles.has(NormalPos)):
			MonsterActorOnPosition = monsterActor
			break

	return MonsterActorOnPosition


func GetRoomStressLevel(Pos : Vector3i) -> int:
	var cell = Data.cells[Pos]
	return cell.stressLevel


func GetClosestPit(Pos : Vector3i, dist : int) -> Vector3i:
	var Closest : Vector3i = Vector3i(999999,99999,99999)
	var ClosestDist : float = 999999999
	var positions = get_points_in_square(Pos, dist)
	for mapPos in positions:
		var cell = Data.cells[mapPos]
		if (cell.type == CellData.CELLTYPE.BONEFIRE):
			var disttoCenter = Pos.distance_squared_to(mapPos)
			if (ClosestDist > disttoCenter):
				ClosestDist = disttoCenter
				Closest = mapPos
	
	return Closest


func get_points_in_square(center: Vector3i, distance: int) -> Array[Vector3i]:
	var points : Array[Vector3i]
	if (Data.cells.has(center)):
		points.append(center)
	for x in range(-distance, distance + 1):
		for z in range(-distance, distance + 1):
			for y in range(-1, 1 + 1):
				# Skip the center point itself
				if x == 0 and z == 0 and y == 0:
					continue
				var loc = center + Vector3i(x, y, z)
				if (Data.cells.has(loc)):
					points.append(loc)

	return points

func get_points_in_square_2D(center: Vector2i, distance: int) -> Array[Vector2i]:
	var points : Array[Vector2i]
	if (Data.cells.has(center)):
		points.append(center)
	for x in range(-distance, distance + 1):
		for y in range(-distance, distance + 1):
			var loc = center + Vector2i(x, y)
			points.append(loc)

	return points


func GetVisible(Pos : Vector3i) -> Array:
	var Suroundings : Array[Vector2i]
	var CurrentRow = -1
	for row in 3:
		var CurrentCollumn = -1
		for collumn in 3:
			var Loc = Vector2i(Pos.x + CurrentRow, Pos.z + CurrentCollumn)
			Suroundings.append(Loc)
			CurrentCollumn += 1
		CurrentRow += 1
	
	var mazeLayer : MazeFloorLayer = GetFloor(Pos.y).GetLayer(FloorLayer.LayerType.MAZE)
	
	var room = mazeLayer.flood_fill_ranged(Vector2i(Pos.x, Pos.z), Suroundings, 2, {})
	return room

signal LoadingFinised
signal LoadingUpdate
var loaded : bool = false

func LoadMapData(MData : MapData) -> void:
	Data = MData
	LoadingFinised.emit()
	loaded = true

func StartGenerationThread(SpawnMonsterOverride : bool = SpawnMonsters) -> void:
	generationThreadTaskID = WorkerThreadPool.add_task(generate_maze.bind(SpawnMonsterOverride))


func ThreadedGenerationFinished() -> void:
	WorkerThreadPool.wait_for_task_completion(generationThreadTaskID)
	GenerationFinished.emit()

func generate_maze(spawnMons : bool) -> void:
	Data = MapData.new()
	
	var r = RandomNumberGenerator.new()
	Data.RandomSeed = RandomSeed
	r.state = hash(RandomSeed)
	Data.RandomState = 1
	Data.DecorationProbability = DecorationProbability


	Data.level = levelScene
	Data.MapDir = scene_file_path

	var tempData = TempGenerationData.NewData(r)
	
	for Floor in Floors:
		#Data.Mazes[FloorIndex] = {}
		var FloorIndex = Floor.FloorNumber
		for y in range(-100, 100):
			var row : Dictionary[int, int] = {}
			
			for x in range(-50, 50):
				var Pos = Vector3i(x, FloorIndex ,y)
				var cellDat = CellData.new()
			
				var cell = Floor.GetLayer(FloorLayer.LayerType.MAZE).get_cell_atlas_coords(Vector2i(x, y)).x
				if (cell == -1):
					continue
				
				Data.cells[Pos] = cellDat

				var Character_Index = Floor.GetLayer(FloorLayer.LayerType.CHARACTERS).get_cell_atlas_coords(Vector2i(x, y)).x
				var Door_Index = Floor.GetLayer(FloorLayer.LayerType.DOORS).get_cell_atlas_coords(Vector2i(x, y)).x
				var Exit_Index = Floor.GetLayer(FloorLayer.LayerType.EXITS).get_cell_atlas_coords(Vector2i(x, y)).x
				
				if (Door_Index != -1):
					if (Door_Index > LevelTransitionCatalogue.size() - 1):
						push_error("Level transition hasn't been configured")
					else:
						cellDat.type = CellData.CELLTYPE.DOOR
						Data.Doors[Pos] = LevelTransitionCatalogue[Door_Index]
				if (Exit_Index != -1):
					if (Exit_Index > LevelTransitionCatalogue.size() - 1):
						push_error("Level transition hasn't been configured")
					else:
						cellDat.type = CellData.CELLTYPE.EXIT
						Data.Exits[Pos] = LevelTransitionCatalogue[Exit_Index]
				
				var layerGenerationData : TempLayerGenerationData = TempLayerGenerationData.NewData(Floor)
				
				#Layer mapping-------------------------------------
				for g in Floor.layerProcessPriority:
					var layer = Floor.Layers[g]
					layer.HandleCell(cellDat, Pos, self, layerGenerationData, tempData)


				if (Character_Index > -1 and CharacterCatalogue.size() > Character_Index):
					cellDat.AddData("Recruit", load(CharacterCatalogue[Character_Index]))
				
				#Floor
				if (layerGenerationData.SpawnFloor and cellDat.type != CellData.CELLTYPE.FALL and cellDat.type != CellData.CELLTYPE.DOWN_LADDER):
					cellDat.spawnFloor = true

				if (layerGenerationData.SpawnDeco):
					var t = Transform3D(Basis(), Pos * WorldScale)
					if (layerGenerationData.SpawnFloor):
						t.origin.y += 0.1
					
					if (cellDat.Custom_Data.has(["Decorations"])):
						cellDat.Custom_Data["Decorations"].append(t)
					else:
						cellDat.Custom_Data["Decorations"] = [t]
					#Data.Decorations.append(t)
				
				var AboveMapPos = Vector3i(x, FloorIndex + 1, y)
				if (Data.cells.has(AboveMapPos)):
					var aboveCell = Data.cells[AboveMapPos]
					#Ceiling
					if (layerGenerationData.SpawnCeiling and Floor.SpawnCeiling and aboveCell.type != CellData.CELLTYPE.FALL and cellDat.type != CellData.CELLTYPE.UP_LADDER):
						cellDat.spawnCeiling = true
						cellDat.floorAsCeiling = Floor.UseFloorAsCeiling
				else:
					if (layerGenerationData.SpawnCeiling and Floor.SpawnCeiling and cellDat.type != CellData.CELLTYPE.UP_LADDER):
						cellDat.spawnCeiling = true
						cellDat.floorAsCeiling = Floor.UseFloorAsCeiling

				row[x] = cell
		
		var mazeLayer : MazeFloorLayer = Floor.GetLayer(FloorLayer.LayerType.MAZE)
		#Monster Spawning
		var rooms =  mazeLayer.separate_into_rooms()
		for room in rooms:
			var StressLevel = 1
			for g in room:
				var cell = Data.cells[Vector3i(g.x, FloorIndex, g.y)]
				if (cell.type == CellData.CELLTYPE.BONEFIRE):
					StressLevel = 0
			for g in room:
				var cell = Data.cells[Vector3i(g.x, FloorIndex, g.y)]
				cell.stressLevel = StressLevel
			if (!spawnMons):
				continue
				
			var monsterLayer : MonsterLayer = Floor.GetLayer(FloorLayer.LayerType.MONSTERS)
			
			var Spawns = monsterLayer.GetMonsterSpawnsOnRoom(room)
			
			for spn : Vector2i in Spawns:
				var spawnPosition = Vector3i(spn.x, FloorIndex, spn.y)
				var monsterActor = MonsterGroup.new()
				if (Spawns.size() == 1):
					monsterActor.Tiles = room
				else:
					monsterActor.Tiles = mazeLayer.flood_fill_ranged(Vector2i(spn.x, spn.y), room, 5, {})
					
				monsterActor.OriginalPos = spawnPosition
				
				#for g in randi_range(1, 1):
				var MonsterID = Floor.GetLayer(FloorLayer.LayerType.MONSTERS).get_cell_atlas_coords(Vector2i(spn.x, spn.y)).x
				if (MonsterID != -1 and MonsterCatalogue.size() > MonsterID):
					var Mon = load(MonsterCatalogue[MonsterID])
					
					var spawnCell = Data.cells[spawnPosition]
					if (spawnCell.HasData("Item")):
						monsterActor.RegisterMonster(Mon, r, spawnCell.Custom_Data["Item"])
						spawnCell.Custom_Data.erase("Item")
					else:
						monsterActor.RegisterMonster(Mon, r)
					
					var cell = Data.GetCell(spawnPosition)
					cell.AddData("MonsterSpawn", monsterActor)
	
	#Back walls
	if (SpawnBackWalls):
		for index in Data.cells.size() / 10.0:
			
			var RandomIndex = r.randi_range(0, Data.cells.size() - 1)
			var Pos = Data.cells.keys()[RandomIndex]
			var cell : CellData = Data.cells[Pos]
			
			if (cell.Custom_Data.has("Lever")):
				continue
			
			if (!cell.HasData("Walls")):
				continue

			var availableWalls : Array[WallData]
			for g : WallData in cell.Custom_Data["Walls"]:
				if (g.Cracked):
					continue
				availableWalls.append(g)

			var BackWallCandidate : WallData = availableWalls[r.randi_range(0, availableWalls.size() - 1)]
			
			#Find the opposite direction
			var oppositedirection = Vector3.LEFT.rotated(Vector3(0,1,0),BackWallCandidate.WallTransform.basis.orthonormalized().get_euler().y)
			
			if (!Data.cells.has(Pos - Vector3i(oppositedirection))):
				continue
				
			var oppositeCell: CellData = Data.cells[Pos - Vector3i(oppositedirection)]
			
			if (oppositeCell.Custom_Data.has("Lever")):
				continue
			
			if (!oppositeCell.HasData("Walls")):
				continue

			var oppositeTransform = BackWallCandidate.WallTransform.origin - (oppositedirection * Vector3(WorldScale))
			var OppositeWallData : WallData
			
			for g in oppositeCell.Custom_Data["Walls"]:
				if (g.WallTransform.origin == oppositeTransform and Helper.are_transforms_opposite(BackWallCandidate.WallTransform, g.WallTransform)):
					OppositeWallData = g
					break
			
			if (OppositeWallData == null):
				continue
			
			cell.Custom_Data["Walls"].erase(BackWallCandidate)
			oppositeCell.Custom_Data["Walls"].erase(OppositeWallData)
			cell.AddDataArr("BackWalls", BackWallCandidate.WallTransform)
			oppositeCell.AddDataArr("BackWalls", OppositeWallData.WallTransform)
	
	#Add a stored variant index value on some walls so that we can use it to add different models to them.
	var Walls : Array[WallData]
	
	#collect all walls
	for g : Vector3i in Data.cells:
		var cell : CellData = Data.GetCell(g)
		
		if (cell.Custom_Data.has("Lever")):
			continue
		
		if (!cell.Custom_Data.has("Walls")):
			continue
		
		if (cell.Custom_Data["Walls"].size() == 0):
			continue
		
		for z in cell.Custom_Data["Walls"]:
			if (!z.Cracked):
				Walls.append(z)
	
	var wallVariantAmm = Walls.size() / 2.0
	#apply a random variant index
	for index in wallVariantAmm:
		var RandomIndex = r.randi_range(0, Walls.size() - 1)
		var wall : WallData = Walls[RandomIndex]
		Walls.remove_at(RandomIndex)
		wall.VariantIndex = r.randi_range(1, 2)
	#store random
	Data.SaveRandomState(r.get_state())
	call_deferred("ThreadedGenerationFinished")

#----------------------- Helper methods -----------------------------#

#-----------------------------------------------
func GetTileAltFromRotation(rot : float) -> int:
	var tile_alternate : int = 0
	match rot:
		PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		PI:
			tile_alternate = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		-PI/2:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
			
	return tile_alternate


#----------------------- EDITOR -----------------------------#
#This area is used when the map is used in editor to generate the geometry for visualisation purposes.
#Once save is pressed the map is regenerated to reflect changes done to the tile map

@export_group("EditorStuff")
@export_tool_button("Redo 3D Map") var Redo3DMapAction = RedoMap
@export_tool_button("Store Props") var StorePropAction = StoreProps



var CurrentlyVisibleFloor : int = 0

#----------------------------------------------------------------
## Stores all mesh instance 3D under the node Extra Props, those will be dynamicly spawned when player is close enough
func StoreProps() -> void:
	Props.clear()
	MegaProps.clear()
	
	for g : MeshInstance3D in $ExtraProps.get_children():
		var MData = MeshData.new()
		MData.Transform = g.transform
		for surface in g.mesh.get_surface_count():
			if (g.get_surface_override_material(surface) != null):
				MData.MatOverride.append(g.get_surface_override_material(surface))

		if (Props.keys().has(g.mesh)):
			Props[g.mesh].append(MData)
		else:
			Props[g.mesh] = [MData]
	
	for g : MeshInstance3D in $MegaProps.get_children():
		var MData = MeshData.new()
		MData.Transform = g.transform
		
		for surface in g.mesh.get_surface_count():
			if (g.get_surface_override_material(surface) != null):
				MData.MatOverride.append(g.get_surface_override_material(surface))

		if (MegaProps.keys().has(g.mesh)):
			MegaProps[g.mesh].append(MData)
		else:
			MegaProps[g.mesh] = [MData]

var _Editor_CurrentWorld : Level
var _Editor_Cam_Zoom : float = 1
#----------------------------------------------------------------
## Used to generate the map in the editor either when editor button is pressed or save notification is received
func RedoMap() -> void:
	StoreProps()
	if (_Editor_CurrentWorld == null):
		RespawnMap()
	else:
		StartGenerationThread(false)
		await GenerationFinished
		_Editor_CurrentWorld.RedoMap(false)
	queue_redraw()
	
#----------------------------------------------------------------
func _notification(what: int) -> void:
	if (what == NOTIFICATION_EDITOR_POST_SAVE):
		print("Redoing map")
		RedoMap()

#----------------------------------------------------------------
func RespawnMap() -> void:
	var NewLevelScene:PackedScene = load(levelScene)
	_Editor_CurrentWorld = NewLevelScene.instantiate()
	get_parent().add_child(_Editor_CurrentWorld)
	StartGenerationThread(false)
	await GenerationFinished
	_Editor_CurrentWorld.configure_map(self)
	_Editor_CurrentWorld.StartBuildingThread(false)

#----------------------------------------------------------------
func _exit_tree() -> void:
	if (_Editor_CurrentWorld != null):
		_Editor_CurrentWorld.queue_free()

#----------------------------------------------------------------
func _on_extra_props_updated() -> void:
	StoreProps()

#----------------------------------------------------------------
## Used to update level with the camera's position so the geo is updated
func _physics_process(delta: float) -> void:
	if (!Engine.is_editor_hint()):
		return
	
	if (_Editor_CurrentWorld == null):
		return
	
	if (EditorInterface.get_editor_viewport_2d() == null):
		return
		
	_Editor_Cam_Zoom = EditorInterface.get_editor_viewport_2d().get_final_transform().x.x
	#print(_Editor_Cam_Zoom)
	
	_Editor_CurrentWorld.Update(delta)
	var camPos = Vector3i(EditorInterface.get_editor_viewport_3d().get_camera_3d().global_position)
	if (editorCamPos != camPos and _Editor_CurrentWorld != null and _Editor_CurrentWorld.GetMapData() != null):
		
		editorCamPos = camPos
		_Editor_CurrentWorld.PlayerPositionChanged(camPos, Vector3.ZERO)
		#print("thing")
	
	if (CheckForFocus(EditorInterface.get_script_editor())):
		return
	
	if (Input.is_key_pressed(KEY_TAB)):
		var Selected = EditorInterface.get_selection().get_selected_nodes()[0]
		var Index = Selected.get_index()
		var Parent = Selected.get_parent()
		
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(Parent.get_child(wrap(Index + 1, 0, Parent.get_child_count())))
	
	if (Input.is_key_label_pressed(KEY_1)):
		for g in get_child_count():
			get_child(g).visible = g == 0
			
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(get_child(0).get_child(0))
		CurrentlyVisibleFloor = -1
		queue_redraw()

	if (Input.is_key_label_pressed(KEY_2)):
		for g in get_child_count():
			get_child(g).visible = g == 1
		
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(get_child(1).get_child(0))
		CurrentlyVisibleFloor = 0
		queue_redraw()

	if (Input.is_key_label_pressed(KEY_3)):
		for g in get_child_count():
			get_child(g).visible = g == 2
		
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(get_child(2).get_child(0))
		CurrentlyVisibleFloor = 1
		queue_redraw()
		
	if (Input.is_key_label_pressed(KEY_4)):
		for g in get_child_count():
			get_child(g).visible = g == 3
		
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(get_child(3).get_child(0))

		CurrentlyVisibleFloor = 2
		queue_redraw()

func CheckForFocus(node : Control) -> bool:
	if (node.has_focus()):
		return true
		
	if (get_child_count() > 0):
		for g in node.get_children():
			if (g is not Control):
				continue
			if (CheckForFocus(g)):
				return true
			
	return false

#----------------------------------------------------------------
## Used to draw various element on the map to help.
## Draws lines from switches to the doors they interact with
## Declares the element of preassure plates, movable and projectile switches
func _draw() -> void:
	if (!Engine.is_editor_hint()):
		return
	
	##Storing of debug lines
	var DebugLines : PackedVector2Array
	var strings : Dictionary[Vector2, Dictionary]
	
	for Floor in Floors:
		
		if (CurrentlyVisibleFloor != Floor.FloorNumber):
			continue
		
		for g in Floor.layerProcessPriority:
			var layer = Floor.GetLayer(g)
			var debugData = layer.GetDebugData(self, Floor.FloorNumber)
	
			for textPos : Vector2 in debugData["Texts"]:
				strings[textPos] = debugData["Texts"][textPos]

			for linePos in debugData["Lines"]:
				DebugLines.append(linePos)
	
	if(DebugLines.size() > 0):
		draw_multiline(DebugLines, Color(1,0,0), 1)
	
	for textPos in strings:
		var textDat = strings[textPos]
		var text = textDat["text"]
		draw_multiline_string(ThemeDB.fallback_font, textPos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 2, -1, textDat["color"])
			
