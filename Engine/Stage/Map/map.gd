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
@export_file("*.res") var ItemCaralogue : Array[String]
@export_file("*.res") var MonsterCatalogue : Array[String]
@export_file("*.res") var CharacterCatalogue : Array[String]

@export_group("Prop Configuration")
#Array of Transform3D
@export var Props : Dictionary[Mesh, Array]


var Data : MapData
var AccumulatedHours : int


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
}

enum TrapType {
	SPIKE_TRAP,
	FIRE_TRAP,
	GUILOTINE_TRAP,
	FIREPIT_TRAP
}

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


func IsWater(Pos : Vector3i) -> bool:
	if (!Data.cells.has(Pos)):
		return false
	return Data.cells[Pos].type == CellData.CELLTYPE.WATER

func IsLava(Pos : Vector3i) -> bool:
	if (!Data.cells.has(Pos)):
		return false
	return Data.cells[Pos].type == CellData.CELLTYPE.LAVA

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
		
	var room = flood_fill_ranged(Vector2i(Pos.x, Pos.z), Suroundings, 2, {}, Pos.y)
	return room

func LoadMapData(MData : MapData) -> void:
	Data = MData

signal GenerationFinished

func StartGenerationThread(SpawnMonsterOverride : bool = SpawnMonsters) -> void:
	var t = Thread.new()
	t.start(generate_maze.bind(t, SpawnMonsterOverride))

func ThreadedGenerationFinished(t : Thread) -> void:
	t.wait_to_finish()
	GenerationFinished.emit()

func generate_maze(Thr : Thread, spawnMons : bool) -> void:
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
		for y in range(-50, 50):
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
						Data.Doors[Pos] = LevelTransitionCatalogue[Door_Index]
				if (Exit_Index != -1):
					if (Exit_Index > LevelTransitionCatalogue.size() - 1):
						push_error("Level transition hasn't been configured")
					else:
						cellDat.type = CellData.CELLTYPE.EXIT
						Data.Exits[Pos] = LevelTransitionCatalogue[Exit_Index]
				
				var layerGenerationData : TempLayerGenerationData = TempLayerGenerationData.NewData(Floor)
				
				#Layer mapping-------------------------------------
				for g in Floor.Layers:
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

		var AllTiles = Floor.GetLayer(FloorLayer.LayerType.MAZE).get_used_cells()
		
		#Monster Spawning
		var rooms = separate_into_rooms(AllTiles, FloorIndex)
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
			var Spawns = GetMonsterSpawnsOnRoom(room, FloorIndex)
			
			for spn in Spawns:
				var monsterActor = MonsterGroup.new()
				if (Spawns.size() == 1):
					monsterActor.Tiles = room
				else:
					monsterActor.Tiles = flood_fill_ranged(Vector2i(spn.x, spn.z), room, 5, {}, FloorIndex)
					
				monsterActor.OriginalPos = spn
				
				#for g in randi_range(1, 1):
				var MonsterID = Floor.GetLayer(FloorLayer.LayerType.MONSTERS).get_cell_atlas_coords(Vector2i(spn.x, spn.z)).x
				if (MonsterID != -1 and MonsterCatalogue.size() > MonsterID):
					var Mon = load(MonsterCatalogue[MonsterID])
					
					var spawnCell = Data.cells[spn]
					if (spawnCell.HasData("Item")):
						monsterActor.RegisterMonster(Mon, r, spawnCell.Custom_Data["Item"])
						spawnCell.Custom_Data.erase("Item")
					else:
						monsterActor.RegisterMonster(Mon, r)
					
					var cell = Data.GetCell(spn)
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
			if (!Data.cells.has(Pos + Vector3i(oppositedirection))):
				continue
			var oppositeCell: CellData = Data.cells[Pos + Vector3i(oppositedirection)]
			
			if (oppositeCell.Custom_Data.has("Lever")):
				continue
			
			if (!oppositeCell.HasData("Walls")):
				continue

			var oppositeTransform = BackWallCandidate.WallTransform.origin + (oppositedirection * Vector3(WorldScale))
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
	call_deferred("ThreadedGenerationFinished", Thr)


func GetFinalRotation(Dir : Vector2i, Rot : float) -> float:
	var FinalRot : float
	match Dir:
		Vector2i.RIGHT:
			FinalRot =  Rot + PI
		Vector2i.LEFT:
			FinalRot = Rot
		Vector2i.UP:
			FinalRot = Rot - PI / 2
		Vector2i.DOWN:
			FinalRot = Rot + PI / 2
	return wrapf(FinalRot, -PI, PI)


func GetMonsterSpawnsOnRoom(room : Array, Floor : int) -> Array[Vector3i]:
	var Spawns : Array[Vector3i]
	for g : Vector2i in GetFloor(Floor).GetLayer(FloorLayer.LayerType.MONSTERS).get_used_cells():
		var ID = GetFloor(Floor).GetLayer(FloorLayer.LayerType.MONSTERS).get_cell_atlas_coords(g)
		if (ID.x == -1):
			continue
		if (room.has(g)):
			Spawns.append(Vector3i(g.x, Floor, g.y))
	return Spawns


func separate_into_rooms(tile_coords: Array, Floor : int) -> Array:
	var rooms := []
	var visited := {}

	for coord in tile_coords:
		if coord in visited:
			continue
		var room = flood_fill(coord, tile_coords, visited, Floor)
		rooms.append(room)

	return rooms


func SeparateIntoCorridors(tile_coords: Array, Floor : int) -> Array:
	var Corridors := []
	var visited := {}

	for coord in tile_coords:
		if coord in visited:
			continue
		var room = flood_fill_ranged(coord, tile_coords, 5, visited, Floor)
		Corridors.append(room)

	return Corridors


func flood_fill(start: Vector2i, tile_coords: Array, visited: Dictionary, Floor : int) -> Array:
	var room : Array = []
	var stack := [start]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current in visited:
			continue

		visited[current] = true
		room.append(current)

		# Get neighboring tiles (4-directional)
		var neighbors : Array[Vector2i] = [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN
		]

		for neighbor in neighbors:
			if current + neighbor in tile_coords and neighbor + current not in visited and !CantReach(current, neighbor, Floor) and !CantReach(current + neighbor, neighbor * -1, Floor):
				stack.push_back(neighbor + current)
	
	return room


func flood_fill_ranged(start: Vector2i, tile_coords: Array, dist : float, visited: Dictionary, Floor : int) -> Array:
	var room : Array = []
	var stack := [start]

	while stack.size() > 0:
		var current = stack.pop_back()

		if current in visited:
			continue

		visited[current] = true
		room.append(current)

		# Get neighboring tiles (4-directional)
		var neighbors : Array[Vector2i] = [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN
		]

		for neighbor in neighbors:
			if start.distance_to(current + neighbor) < dist and current + neighbor in tile_coords and neighbor + current not in visited and !CantReach(current, neighbor, Floor) and !CantReach(current + neighbor, neighbor * -1, Floor):
				stack.push_back(neighbor + current)
	
	return room
	
##Used to declare the blocking direction of each of the MAZE tiles
func CantReach(tilecoords : Vector2, dir : Vector2, Floor : int) -> bool:
	var index = GetFloor(Floor).GetLayer(FloorLayer.LayerType.MAZE).get_cell_atlas_coords(tilecoords).x
	var tilerotation = GetTileRotationRadians(tilecoords, Floor)
	var resault : bool
	match index:
		0:
			resault = false
		1:
			var rotatedv = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rotatedv)
		2:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		3:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		4:
			resault = false
		5:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot2) or dir.is_equal_approx(rot1)
		6:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		7:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		8:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		9:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		10:
			var rot1 = Vector2.RIGHT.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		11:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		12:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		13:
			resault = true
		14:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		15:
			resault = true
		16:
			resault = true
		17:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.RIGHT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot2) or dir.is_equal_approx(rot1)
		18:
			var rot1 = Vector2.DOWN.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		19:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = !dir.is_equal_approx(rot1)
		20:
			resault = false
		21:
			resault = false
		22:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		23:
			var rot1 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		24:
			resault = false
		25:
			resault = false
		26:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.DOWN.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		27:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			var rot2 = Vector2.UP.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1) or dir.is_equal_approx(rot2)
		28:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		29:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
		30:
			var rot1 = Vector2.LEFT.rotated(tilerotation)
			resault = dir.is_equal_approx(rot1)
	return resault


#TODO fix this, we dont need all those separate functions
#----------------------------------------------------------------
func Testtile(pos : Vector2i, Floor : int) -> int:
	var tile_alternate : int = 0
	var rot = GetTileRotationDegrees(pos, Floor)
	match rot:
		-90.0:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
		180.0:
			tile_alternate = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
		90.0:
			tile_alternate = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
	return tile_alternate

#----------------------------------------------------------------
func GetTileRotationDegrees(pos : Vector2i, Floor : int, Layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE) -> float:
	var rot : float = 0

	if GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		rot = 0
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		rot = -90
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		rot = 90
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		rot = 180
	return rot

#----------------------------------------------------------------
func GetTileRotationRadians(pos : Vector2i, Floor : int, Layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE) -> float:
	var rot : float = 0
	if GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		rot = 0
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		rot = PI/2
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		rot = -PI/2
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		rot = PI
	return rot

#----------------------------------------------------------------
func GetTileDirection(pos : Vector2i, Floor : int, Layer : FloorLayer.LayerType = FloorLayer.LayerType.MAZE) -> Vector2:
	var Dir : Vector2 = Vector2.RIGHT
	if GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		Dir = Vector2.RIGHT
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == false:
		Dir = Vector2.DOWN
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == false and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		Dir = Vector2.UP
	elif GetFloor(Floor).GetLayer(Layer).is_cell_flipped_h(pos) == true and GetFloor(Floor).GetLayer(Layer).is_cell_flipped_v(pos) == true:
		Dir = Vector2.LEFT
	return Dir


#----------------------- EDITOR -----------------------------#
#This area is used when the map is used in editor to generate the geometry for visualisation purposes.
#Once save is pressed the map is regenerated to reflect changes done to the tile map

@export_group("EditorStuff")
@export_tool_button("Redo 3D Map") var Redo3DMapAction = RedoMap
@export_tool_button("Store Props") var StorePropAction = StoreProps

##Storing of debug lines
var DebugLines : Array[Array]

var CurrentlyVisibleFloor : int = 0

#----------------------------------------------------------------
## Stores all mesh instance 3D under the node Extra Props, those will be dynamicly spawned when player is close enough
func StoreProps() -> void:
	Props.clear()
	for g : MeshInstance3D in $ExtraProps.get_children():
		var MData = MeshData.new()
		MData.Transform = g.transform
		if (g.get_surface_override_material(0) != null):
			MData.MatOverride = g.get_surface_override_material(0)
		else: if (g.material_override != null):
			MData.MatOverride = g.material_override
		if (Props.keys().has(g.mesh)):
			Props[g.mesh].append(MData)
		else:
			Props[g.mesh] = [MData]

var _Editor_CurrentWorld : Level
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
		
	_Editor_CurrentWorld.Update(delta)
	var camPos = Vector3i(EditorInterface.get_editor_viewport_3d().get_camera_3d().global_position)
	if (editorCamPos != camPos and _Editor_CurrentWorld != null and _Editor_CurrentWorld.GetMapData() != null):
		
		editorCamPos = camPos
		_Editor_CurrentWorld.PlayerPositionChanged(camPos, Vector3.ZERO)
		#print("thing")
	
	#if (Input.is_key_pressed(KEY_TAB)):
		#var Selected = EditorInterface.get_selection().get_selected_nodes()[0]
		#var Index = Selected.get_index()
		#var Parent = Selected.get_parent()
		#EditorInterface.edit_node(Parent.get_child(wrap(Index + 1, 0, Parent.get_child_count())))
		#
	#if (Input.is_key_label_pressed(KEY_1)):
		#for g in get_child_count():
			#get_child(g).visible = g == 0
		#EditorInterface.edit_node(get_child(0).get_child(0))
		#CurrentlyVisibleFloor = -1
		##update()
	#if (Input.is_key_label_pressed(KEY_2)):
		#for g in get_child_count():
			#get_child(g).visible = g == 1
		#EditorInterface.edit_node(get_child(1).get_child(0))
		#CurrentlyVisibleFloor = 0
		##Update()
	#if (Input.is_key_label_pressed(KEY_3)):
		#for g in get_child_count():
			#get_child(g).visible = g == 2
		#EditorInterface.edit_node(get_child(2).get_child(0))
		#CurrentlyVisibleFloor = 1
		##Update()
	#if (Input.is_key_label_pressed(KEY_4)):
		#for g in get_child_count():
			#get_child(g).visible = g == 3
		#EditorInterface.edit_node(get_child(3).get_child(0))
		#CurrentlyVisibleFloor = 2
		##Update()


#----------------------------------------------------------------
## Used to draw various element on the map to help.
## Draws lines from switches to the doors they interact with
## Declares the element of preassure plates, movable and projectile switches
func _draw() -> void:
	if (!Engine.is_editor_hint()):
		return
		
	DebugLines.clear()
	
	for Floor in Floors:
		var LeverLayer = Floor.GetLayer(FloorLayer.LayerType.LEVERS)
		for LeverPosition in LeverLayer.get_used_cells():
			var Index = LeverLayer.get_cell_atlas_coords(LeverPosition).x
			
			var TextDrawPos = LeverLayer.map_to_local(LeverPosition)
			TextDrawPos.x -= var_to_str(Index).length() * 2
			TextDrawPos.y += 10
			draw_string(ThemeDB.fallback_font, TextDrawPos, var_to_str(Index), HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0,1,0))
			
			if (LeverCatalogue.size() - 1 < Index):
				printerr("Lever of Index {0} hasn't been configured in {1}".format([Index, LocationName.keys()[LevelName]]))
				continue
			var Dat = LeverCatalogue[Index]
			if (Dat is DoorLeverCallInfo):
				var UnlockPosition = Dat.DoorLoc
				if (UnlockPosition == Vector3i.ZERO):
					if (CurrentlyVisibleFloor != Floor.FloorNumber):
						continue
					DebugLines.append([LeverLayer.map_to_local(LeverPosition), LeverLayer.map_to_local(LeverPosition), Vector3i(LeverPosition.x, Floor.FloorNumber, LeverPosition.y)])
				else:
					if (CurrentlyVisibleFloor != Floor.FloorNumber and CurrentlyVisibleFloor != UnlockPosition.y):
						continue
					DebugLines.append([LeverLayer.map_to_local(LeverPosition), LeverLayer.map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)), UnlockPosition])
			if (Dat is BridgeLeverCallInfo):

				var UnlockPositions = Dat.FloorPos
				for Pos in UnlockPositions:
					DebugLines.append([LeverLayer.map_to_local(LeverPosition), LeverLayer.map_to_local(Vector2(Pos.x, Pos.z)), Vector3i(LeverPosition.x, Floor.FloorNumber, LeverPosition.y)])

		var PlateLayer = Floor.GetLayer(FloorLayer.LayerType.PLATES)
		for PlatePosition in PlateLayer.get_used_cells():
			var Index = PlateLayer.get_cell_atlas_coords(PlatePosition).x
			if (PlateCatalogue.size() - 1 < Index):
				printerr("Plate of Index {0} hasn't been configured in {1}".format([Index, LocationName.keys()[LevelName]]))
				continue
			var Dat = PlateCatalogue[Index]
			
			var TextDrawPos = LeverLayer.map_to_local(PlatePosition)
			var text = "{0}\n{1}".format([Index, PreassuerPlateData.SwitchElement.keys()[Dat.Element]])
			
			TextDrawPos.y += 10
			var lines = text.split("\n")
			for line in lines:
				TextDrawPos.x -= line.length() * 2
				draw_string(ThemeDB.fallback_font, TextDrawPos, line, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0,1,0))
				TextDrawPos.y = TextDrawPos.y + 10

			if (Dat is DoorPreassurePlateCallInfo):
				var UnlockPosition = Dat.DoorLoc
				if (UnlockPosition == Vector3i.ZERO):
					if (CurrentlyVisibleFloor != Floor.FloorNumber):
						continue
					DebugLines.append([PlateLayer.map_to_local(PlatePosition), PlateLayer.map_to_local(PlatePosition), Vector3i(PlatePosition.x, Floor.FloorNumber, PlatePosition.y)])
				else:
					if (CurrentlyVisibleFloor != Floor.FloorNumber and CurrentlyVisibleFloor != UnlockPosition.y):
						continue
					DebugLines.append([PlateLayer.map_to_local(PlatePosition), PlateLayer.map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)), UnlockPosition])
			
		var MovableLayer = Floor.GetLayer(FloorLayer.LayerType.MOVABLES)
		for MovablePosition in MovableLayer.get_used_cells():
			var Index = MovableLayer.get_cell_atlas_coords(MovablePosition).x
			if (MovableCatalogue.size() - 1 < Index):
				printerr("Movable of Index {0} hasn't been configured in {1}".format([Index, LocationName.keys()[LevelName]]))
				continue
			var Dat = MovableCatalogue[Index]
			
			var TextDrawPos = MovableLayer.map_to_local(MovablePosition)
			var text = "{0}\n{1}".format([Index, PreassuerPlateData.SwitchElement.keys()[Dat.Element]])
			
			TextDrawPos.y += 10
			var lines = text.split("\n")
			for line in lines:
				TextDrawPos.x -= line.length() * 2
				draw_string(ThemeDB.fallback_font, TextDrawPos, line, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0,1,0))
				TextDrawPos.y = TextDrawPos.y + 10
		
		var LockLayer = Floor.GetLayer(FloorLayer.LayerType.LOCKS)
		for LockPosition in LockLayer.get_used_cells():
			var Index = LockLayer.get_cell_atlas_coords(LockPosition).x
			if (LockCatalogue.size() - 1 < Index):
				printerr("Lock of Index {0} hasn't been configured in {1}".format([Index, LocationName.keys()[LevelName]]))
				continue
			var Dat = LockCatalogue[Index]
			
			var TextDrawPos = LockLayer.map_to_local(LockPosition)
			var text = "{0}\n{1}".format([Index, Dat.ItemName])
			
			TextDrawPos.y += 10
			var lines = text.split("\n")
			for line in lines:
				TextDrawPos.x -= line.length() * 2
				draw_string(ThemeDB.fallback_font, TextDrawPos, line, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0,1,0))
				TextDrawPos.y = TextDrawPos.y + 10
		
		var ProjectileSwitchLayer = Floor.GetLayer(FloorLayer.LayerType.PROJECTILE_SWITCH)
		for ProjectileSwitchPosition in ProjectileSwitchLayer.get_used_cells():
			var Index = ProjectileSwitchLayer.get_cell_atlas_coords(ProjectileSwitchPosition).x
			if (ProjectileSwitchCatalogue.size() - 1 < Index):
				printerr("Projectile switch of Index {0} hasn't been configured in {1}".format([Index, LocationName.keys()[LevelName]]))
				continue
			var Dat = ProjectileSwitchCatalogue[Index]
			
			var TextDrawPos = LeverLayer.map_to_local(ProjectileSwitchPosition)
			var text = "{0}\n{1}".format([Index, ProjectileSwitchData.SwitchElement.keys()[Dat.Element]])
			
			TextDrawPos.y += 10
			var lines = text.split("\n")
			for line in lines:
				TextDrawPos.x -= line.length() * 2
				draw_string(ThemeDB.fallback_font, TextDrawPos, line, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(0,1,0))
				TextDrawPos.y = TextDrawPos.y + 10

			if (Dat is DoorProjectileSwitchCallInfo):
				var UnlockPosition = Dat.DoorLoc
				if (UnlockPosition == Vector3i.ZERO):
					if (CurrentlyVisibleFloor != Floor.FloorNumber):
						continue
					DebugLines.append([ProjectileSwitchLayer.map_to_local(ProjectileSwitchPosition), ProjectileSwitchLayer.map_to_local(ProjectileSwitchPosition), Vector3i(ProjectileSwitchPosition.x, Floor.FloorNumber, ProjectileSwitchPosition.y)])
				else:
					if (CurrentlyVisibleFloor != Floor.FloorNumber and CurrentlyVisibleFloor != UnlockPosition.y):
						continue
					DebugLines.append([ProjectileSwitchLayer.map_to_local(ProjectileSwitchPosition), ProjectileSwitchLayer.map_to_local(Vector2i(UnlockPosition.x, UnlockPosition.z)), UnlockPosition])
			if (Dat is BridgeProjectileSwitchCallInfo):
				var UnlockPositions = Dat.FloorPos
				for Pos in UnlockPositions:
					DebugLines.append([ProjectileSwitchLayer.map_to_local(Vector2(Pos.x, Pos.z)), ProjectileSwitchLayer.map_to_local(ProjectileSwitchPosition), Vector3i(ProjectileSwitchPosition.x, Floor.FloorNumber, ProjectileSwitchPosition.y)])

	for g in DebugLines:
		draw_line(g[0], g[1], Color(1,0,0), 2)
		var text : String = "{0}|{1}|{2}".format([g[2].x, g[2].y, g[2].z])
		var TextDrawPos = g[1]
		TextDrawPos.x -= text.length() * 2
		TextDrawPos.y -= 10
		draw_string(ThemeDB.fallback_font, TextDrawPos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color(1,0,0))
