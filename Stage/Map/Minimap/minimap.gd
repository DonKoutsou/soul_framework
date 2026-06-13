extends PanelContainer

class_name Minimap

@export var TileLayers : Dictionary[int, Array]

@export var LocationLabel : Label
@export var PlayerSprite : Sprite2D
@export var Camera : Camera2D
#@export var TravelLine : TravelHistory

var InitialSize : Vector2
var MapBig : bool = false

var Spawns : Dictionary

var PlPos : Vector2
var CurrentFloor : int
var CamOffset : Vector2
var OriginalPosiotion : Vector2

static var ShowMinimap : bool = false
static var Instance : Minimap

var StoredData : Dictionary[Map.LocationName, MinimapData]

func StoreCurrentWorldData(CurrentWorldName : Map.LocationName) -> void:
	var Data = MinimapData.new()
	for Floor in range(-1, 1):
		var FloorData : Dictionary = {}
		for Layer in 3:
			var LayerData : Dictionary[Vector2i, int] = {}
			var UsedCells : Array[Vector2i] = get_node(TileLayers[Floor][Layer]).get_used_cells()
			for CellCoords in UsedCells:
				LayerData[CellCoords] = get_node(TileLayers[Floor][Layer]).get_cell_atlas_coords(CellCoords).x
			FloorData[Layer] = LayerData
			
		Data.FloorData[Floor] = FloorData
	StoredData[CurrentWorldName] = Data

func LoadWorldData(CurrentWorldName : Map.LocationName) -> void:
	for Floor in range(-1, 1):
		for Layer in 3:
			get_node(TileLayers[Floor][Layer]).clear()
			
	if (!StoredData.has(CurrentWorldName)):
		return
		
	var Data = StoredData[CurrentWorldName]
	for Floor in range(-1, 1):
		var FloorData : Dictionary = Data.FloorData[Floor]
		for Layer in 3:
			#Is dict with vector2i as key and int as value
			var LayerData : Dictionary[Vector2i, int] = FloorData[Layer]
			for CellCoords in LayerData.keys():
				var Value = LayerData[CellCoords]
				var TileRotation = Stage.CurrentWorld.MData.GetFloor(Floor).GetLayer(FloorLayer.LayerType.MAZE).Testtile(CellCoords)
				if (Layer == 0):
					get_node(TileLayers[Floor][Layer]).set_cell(CellCoords, 10 , Vector2i(Value, 0), TileRotation)
				else:
					get_node(TileLayers[Floor][Layer]).set_cell(CellCoords, 0 , Vector2i(Value, 0), TileRotation)
			
			
			
func _ready() -> void:
	InitialSize = size
	Instance = self
	visible = ShowMinimap
	OriginalPosiotion = position
	#TravelLine.add_point(Vector2(0,0))

func OnPositionSeen(Pos : Vector3i) -> void:
	#Find the tile coordinates
	var Floor : int = roundi(Pos.y)
	var mappos = Vector2i(Pos.x, Pos.z)
	#Check if outside map
	if (IsOusideMap(Pos)):
		return
	
	var Mp = Stage.CurrentWorld.MData
	
	var cell : CellData = Mp.Data.GetCell(Pos)
	
	var CurrentFloorLayer = Mp.GetFloor(Floor).GetLayer(FloorLayer.LayerType.MAZE)
	var AtlasCoords = CurrentFloorLayer.get_cell_atlas_coords(mappos)
	if (AtlasCoords.x == -1):
		return
	#Get index of texture in atlas
	var TileIndex = Vector2i(AtlasCoords.x, 0)
	var TileRotation = Mp.GetFloor(Floor).GetLayer(FloorLayer.LayerType.MAZE).Testtile(mappos)
	if (!TileLayers.keys().has(CurrentFloor)):
		return
	get_node(TileLayers[CurrentFloor][0]).set_cell(mappos, 10, TileIndex, TileRotation)
	
	#Check if lock
	if (cell.HasData("Locks")):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(0,0))
	else: if (cell.HasData("Chest")):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(0,0))
	else: if (cell.HasData("MasterLocks")):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(2,0))
	else : if (cell.HasData("Trap")):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(5,0))
	else : if (cell.HasData("Door") and cell.Custom_Data["Door"].Blocked):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(4,0))
	else : if (cell.type == CellData.CELLTYPE.BONEFIRE):
		get_node(TileLayers[CurrentFloor][2]).set_cell(mappos, 0, Vector2i(15,0))
	else:
		get_node(TileLayers[CurrentFloor][2]).erase_cell(mappos)
		
	#Check if ladder
	if (cell.type == CellData.CELLTYPE.UP_LADDER):
		get_node(TileLayers[CurrentFloor][1]).set_cell(mappos, 0, Vector2i(4,0))
	if (cell.type == CellData.CELLTYPE.DOWN_LADDER):
		get_node(TileLayers[CurrentFloor][1]).set_cell(mappos, 0, Vector2i(5,0))
	if (cell.type == CellData.CELLTYPE.FALL):
		get_node(TileLayers[CurrentFloor][1]).set_cell(mappos, 0, Vector2i(6,0))
	
func OnBlockOpened(Pos : Vector3i) -> void:
	
	if (IsOusideMap(Pos)):
		return
		
	get_node(TileLayers[Pos.y][2]).erase_cell(Vector2i(Pos.x, Pos.z))

func OnBlockClosed(Pos : Vector3i) -> void:
	if (IsOusideMap(Pos)):
		return
		
	get_node(TileLayers[Pos.y][2]).set_cell(Vector2i(Pos.x, Pos.z), 0, Vector2i(4,0))

func OnDoorUnlocked(Pos : Vector3i) -> void:
	if (IsOusideMap(Pos)):
		return
		
	get_node(TileLayers[Pos.y][2]).erase_cell(Vector2i(Pos.x, Pos.z))

func OnPositionVisited(Pos : Vector3i, Direction : float) -> void:
	
	var mappos = Vector2(Pos.x, Pos.z)
	
	#if (IsOusideMap(mappos)):
		#return
		
	var Floor = Pos.y
	for FloorIndex in TileLayers.keys():
		for Layer in TileLayers[FloorIndex]:
			get_node(Layer).visible = FloorIndex == Floor
	#TravelLine.NewPoint(Pos - (Vector2.LEFT.rotated(-Direction) * 4))
	PlPos = (mappos * 16.0) + Vector2(8,8)
	#Allign camera to position, Add 8 to center it to tile
	Camera.position = PlPos
	#Rotate tile to face direction 
	PlayerSprite.rotation = -Direction
	CurrentFloor = Floor
	#Find the tile coordinates
	#var mappos = Vector2(Pos)
	#check if outside map
	
	#Set coordinates on map label
	var p = mappos.abs()
	p.y -= 1
	var Dir = wrapf(Direction, -PI, PI)
	LocationLabel.text = "{0}\n{1}".format([Helper.AngleToDirection(Dir),Vector3i(p.x, Floor, p.y)])
	
	
	

func IsOusideMap(Pos : Vector3i) -> bool:
	return !Stage.CurrentWorld.GetMapData().cells.has(Pos)

func ToggleMinimap(t : bool) -> void:
	#visible = t
	if (t):
		visible = true
		size = get_viewport_rect().size
		MapBig = true
		Camera.zoom = Vector2(0.5,0.5)
		position = Vector2.ZERO
		#set_physics_process(true)
		CamOffset = Vector2.ZERO
	else:
		position = OriginalPosiotion
		
		visible = ShowMinimap
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		size = InitialSize
		MapBig = false
		Camera.zoom = Vector2(0.8,0.8)
	
	Camera.position = PlPos
	PlayerSprite.position = Vector2.ZERO
	Camera.position_smoothing_enabled = !MapBig
	#set_physics_process(MapBig)

func _physics_process(_delta: float) -> void:
	if (MapBig):
		if (Input.is_action_pressed("move_forward")):
			CamOffset.y -= 4
		if (Input.is_action_pressed("move_back")):
			CamOffset.y += 4
		if (Input.is_action_pressed("look_left")):
			CamOffset.x -= 4
		if (Input.is_action_pressed("look_right")):
			CamOffset.x += 4
		Camera.position = PlPos +CamOffset
		PlayerSprite.position = - CamOffset

func _input(event: InputEvent) -> void:
	if (MapBig):
		if (event is InputEventMouseMotion and Input.is_action_pressed("AtackLeft")):
			var dir = event.relative / Camera.zoom
			CamOffset -= dir
		if (event.is_action_pressed("zoom_in")):
			Camera.zoom = clamp(Camera.zoom + Vector2(0.1,0.1), Vector2(0.2,0.2), Vector2(4,4))
		if (event.is_action_pressed("zoom_out")):
			Camera.zoom = clamp(Camera.zoom - Vector2(0.1,0.1), Vector2(0.2,0.2), Vector2(4,4))
		
