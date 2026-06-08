extends Node3D

class_name LevelEnviromentSoundManager

var Data : Map

var Sounds : Dictionary[Vector3i, AudioStreamPlayer3D]

@export var DebugMesh : Mesh
@export var SoundRange : int = 1
@export var WaterSound : AudioStream
@export var LavaSound : AudioStream

func PlayerLocationChanged(NewPos : Vector3i) -> void:
	#var CurrentSoundRange = SoundRange * Level.CurrentWorldScale
	var FloorIndex = NewPos.y - SoundRange
	var RowIndex = NewPos.z - SoundRange
	var CollumnIndex = NewPos.x - SoundRange
	for Floor in 1 + (2 * SoundRange):
		for Row in 1 + (2 * SoundRange):
			for Collumn in 1 + (2 * SoundRange):
				var Pos = Vector3i(CollumnIndex, FloorIndex, RowIndex)
				
				if (!Sounds.has(Pos)):
					var IsWater = Data.IsWater(Pos)
					if (IsWater):
						var NewSound = AudioStreamPlayer3D.new()
						NewSound.stream = WaterSound
						NewSound.unit_size = 1
						add_child(NewSound)
						
						NewSound.position = Pos * Level.CurrentWorldScale
						var Similar = FindSimilar(WaterSound)
						if (Similar):
							var SoundPos = Similar.get_playback_position()
							NewSound.play(SoundPos)
							#NewSound.seek(SoundPos)
						else:
							NewSound.play()
						Sounds[Pos] = NewSound
						if (OS.is_debug_build()):
							var Me = MeshInstance3D.new()
							Me.mesh = DebugMesh
							NewSound.add_child(Me)
							Me.position.y += 0.5
					var IsLava = Data.IsLava(Pos)
					if (IsLava):
						var NewSound = AudioStreamPlayer3D.new()
						NewSound.stream = LavaSound
						NewSound.unit_size = 1
						add_child(NewSound)
						
						NewSound.position = Pos * Level.CurrentWorldScale
						var Similar = FindSimilar(LavaSound)
						if (Similar):
							var SoundPos = Similar.get_playback_position()
							NewSound.play(SoundPos)
							#NewSound.seek(SoundPos)
						else:
							NewSound.play()
						Sounds[Pos] = NewSound
						if (OS.is_debug_build()):
							var Me = MeshInstance3D.new()
							Me.mesh = DebugMesh
							NewSound.add_child(Me)
							Me.position.y += 0.5
				CollumnIndex += 1
			CollumnIndex = NewPos.x - SoundRange
			RowIndex += 1
		RowIndex = NewPos.z - SoundRange
		FloorIndex += 1
	for g in range(Sounds.size() - 1, -1, -1):
		var key = Sounds.keys()[g]
		if (key.distance_to(NewPos) > SoundRange + 0.5):
			Sounds[key].queue_free()
			Sounds.erase(key)

func FindSimilar(Audiostream : AudioStream) -> AudioStreamPlayer3D:
	for g in Sounds.values():
		if (g.stream == Audiostream):
			return g
	return null
