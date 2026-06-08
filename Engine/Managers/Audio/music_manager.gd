extends Node

class_name MusicManager

@export var SoundLibrary : Dictionary[Music, AudioStream]
@export var SoundVolumes : Dictionary[Music, float]

static var Musics : Dictionary[Music, AudioStreamPlayer]

static var Instance : MusicManager

func _ready() -> void:
	Instance = self
	for g in SoundLibrary:
		var Sound = AudioStreamPlayer.new()
		add_child(Sound)
		Sound.volume_db = SoundVolumes[g]
		Sound.bus = "Music"
		Sound.stream = SoundLibrary[g]
		Musics[g] = Sound
		if (g == Music.MAIN):
			Sound.play()

func PauseMusic(t : bool) -> void:
	if (t):
		print("Music Paused")
	else:
		print("Music Unpaused")
	for g in Musics:
		var Pl = Musics[g]
		Pl.stream_paused = t

func PlayerMusic(MusicType : Music) -> void:
	for g in Musics:
		if (g == MusicType):
			Musics[g].playing = true
			Musics[g].volume_db = -60
			var tw = create_tween()
			tw.tween_property(Musics[g], "volume_db", SoundVolumes[g], 2)
		else:
			var tw = create_tween()
			tw.tween_property(Musics[g], "volume_db", -60, 2)
			tw.finished.connect(DissableAudio.bind(Musics[g]))
	
func DissableAudio(Pl : AudioStreamPlayer) -> void:
	Pl.playing = false

enum Music{
	MAIN,
	FIGHT,
}
