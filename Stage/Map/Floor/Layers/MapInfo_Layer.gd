@tool
extends BaseFloorLayer

class_name MapInfoLayer


func HandleCell(cellDat : CellData, Pos : Vector3i, map : Map, tempLayerData : TempLayerGenerationData, tempData : TempGenerationData) -> void:
	var index = get_cell_atlas_coords(Vector2i(Pos.x, Pos.z)).x

	match index:
		#empty
		0:
			pass
			#Locks.append(Pos)
		#Breakable obstacle
		1:
			var T = Transform3D(Basis().rotated(Vector3(0,1,0), tempData.r.randf_range(-PI * 2, PI * 2)), Pos * map.WorldScale)
			cellDat.Custom_Data["Breakable"] = T
			tempLayerData.SpawnDeco = false
		#Master Lock
		2:
			tempData.MasterLocks.append(Pos)
		#3 Soft Breakable obstacle
		3:
			var T = Transform3D(Basis().rotated(Vector3(0,1,0), tempData.r.randf_range(-PI * 2, PI * 2)), Pos * map.WorldScale)
			cellDat.Custom_Data["SoftBreakable"] = T
		#Closed door, either to be unlocked by switch/lever or to stay closed
		4:
			tempData.Blocks.append(Pos)
		#Spike trap
		5:
			var TrapDat = MapTrapData.new()
			var B = Basis().scaled(Vector3(1,1,1) * (map.WorldScale / 2.0))
			var Trans = Transform3D(B, (Pos * map.WorldScale))
			TrapDat.TrapTransform = Trans
			TrapDat.TrapType = Map.TrapType.SPIKE_TRAP
			cellDat.AddData("Trap", TrapDat)
			#AddDeco = false
		#Wall crack
		6:
			tempData.Cracks[Pos] = GetTileDirection(Vector2i( Pos.x, Pos.z))
		#Light door
		7:
			cellDat.AddData("LightDoor", LightDoorData.new())
			#Data.LightDoorList[Pos] = null
		#Fire trap
		8:
			var TrapDat = MapTrapData.new()
			
			var rot = GetTileRotationRadians(Vector2i( Pos.x, Pos.z))
			var B = Basis().scaled(Vector3(1,1,1) * (map.WorldScale / 2.0))
			var Trans = Transform3D(B.rotated(Vector3(0,1,0), rot), Pos * map.WorldScale + Vector3i(0,1,0))
			TrapDat.TrapType = Map.TrapType.FIRE_TRAP
			TrapDat.TrapTransform = Trans
			
			cellDat.AddData("Trap", TrapDat)
		#Drop
		9:
			tempLayerData.SpawnDeco = false
			var BellowMapPos = Vector3i(Pos.x, Pos.y - 1, Pos.z)
			if (map.Data.cells.has(BellowMapPos)):
				var BelloCell = map.Data.cells[BellowMapPos]
				BelloCell.CrackedCeiling = true
			cellDat.CrackedFloor = true
		#Guilotine
		10:
			var TrapDat = MapTrapData.new()
			var rot = deg_to_rad(GetTileRotationDegrees( Vector2i(Pos.x, Pos.z)))
			var Trans = Transform3D(Basis().rotated(Vector3(0,1,0), rot), Pos * map.WorldScale)
			TrapDat.TrapTransform = Trans
			TrapDat.TrapType = Map.TrapType.GUILOTINE_TRAP
			#Data.Traps[Pos] = TrapDat
			cellDat.AddData("Trap", TrapDat)
		#Blocking decoration
		11:
			var t = Transform3D(Basis(), Pos * map.WorldScale)
			t = t.rotated_local(Vector3(0,1,0), deg_to_rad(GetTileRotationDegrees(Vector2i(Pos.x, Pos.z))))
			cellDat.AddData("BlockingDeco", t)
			#Data.BlockingDecoration[Pos] = t
			tempLayerData.SpawnDeco = false
		#Blocking decoration2
		12:
			cellDat.type = CellData.CELLTYPE.ENDPOINT
			
		#Fall, already broken floor
		13:
			cellDat.type = CellData.CELLTYPE.FALL
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = false
			var BellowMapPos = Vector3i(Pos.x, Pos.y - 1, Pos.z)
			if (map.Data.cells.has(BellowMapPos)):
				map.Data.cells[BellowMapPos].spawnCeiling = false
		#Spawnpoint
		14:
			map.Data.SpawnPoint = Pos
			map.Data.SpawnRot = deg_to_rad(GetTileRotationDegrees(Vector2i(Pos.x, Pos.z)))
		#Fire pit
		15:
			cellDat.type = CellData.CELLTYPE.BONEFIRE
			tempLayerData.SpawnDeco = false
		#Water
		16:
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = tempLayerData.Floor.AddDecorationOnWater
			cellDat.type = CellData.CELLTYPE.WATER
		#Ladder Up
		17:
			cellDat.type = CellData.CELLTYPE.UP_LADDER
		#Ladder Down
		18:
			cellDat.type = CellData.CELLTYPE.DOWN_LADDER
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = false
		#House
		19:
			var rot2 = GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
			var T = Transform3D(Basis().rotated(Vector3(0,1,0), rot2), (Pos * map.WorldScale))
			cellDat.Custom_Data["House"] = T
		# Recruit 1
		20:
			pass
			#cellDat.AddData("Recruit", load("res://Resources/Characters/Alice.tres").duplicate(true))
			#Data.Recruits[Pos] = load("res://Resources/Characters/Alice.tres").duplicate(true)
		# Recruit 2
		21:
			pass
			#cellDat.AddData("Recruit", load("res://Resources/Characters/Oliver.tres").duplicate(true))
			#Data.Recruits[Pos] = load("res://Resources/Characters/Oliver.tres").duplicate(true)
		#Lava
		22:
			tempLayerData.SpawnFloor = false
			cellDat.type = CellData.CELLTYPE.LAVA
			tempLayerData.SpawnDeco = tempLayerData.Floor.AddDecorationOnWater
		#Gap
		23:
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = false
			cellDat.type = CellData.CELLTYPE.GAP
		#Stairs going up
		24:
			var rot2 = GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
			var T = Transform3D(Basis().rotated(Vector3(0,1,0), rot2), (Pos * map.WorldScale))
			cellDat.Custom_Data["UP_STAIRS"] = T
			cellDat.type = CellData.CELLTYPE.UP_STAIRS
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = false
			tempLayerData.SpawnCeiling = false
		#Stairs going down
		25: 
			var rot2 = GetTileRotationRadians(Vector2i(Pos.x, Pos.z))
			var Position = Vector3i(Pos.x, Pos.y - 1, Pos.z)
			var T = Transform3D(Basis().rotated(Vector3(0,1,0), rot2), (Position * map.WorldScale))
			cellDat.Custom_Data["DOWN_STAIRS"] = T
			#Data.StairsDown[Pos] = T
			cellDat.type = CellData.CELLTYPE.DOWN_STAIRS
			tempLayerData.SpawnFloor = false
			tempLayerData.SpawnDeco = false
		26: 
			cellDat.AddData("Door", DoorData.new())
		27:
			cellDat.type = CellData.CELLTYPE.DUGGABLE
			tempLayerData.SpawnDeco = false
