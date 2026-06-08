extends Node

class_name WorldTimeManager

static var GameFrameTimeMulti : float = 1.0

static var Instance : WorldTimeManager

func _ready() -> void:
	Instance = self

func StopTime(T : float = 0.25, Ease : Tween.EaseType = Tween.EASE_OUT) -> void:
	var tw = create_tween()
	tw.set_ease(Ease)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_method(UpdateTime, GameFrameTimeMulti, 0.0, T)
	#tw.tween_property(self, "GameFrameTimeMulti", 0.0, T)
	
func StartTime(T : float = 0.25, Ease : Tween.EaseType = Tween.EASE_IN) -> void:
	var tw = create_tween()
	tw.set_ease(Ease)
	tw.set_trans(Tween.TRANS_QUINT)
	tw.tween_method(UpdateTime, GameFrameTimeMulti, 1.0, T)
	#tw.tween_property(self, "GameFrameTimeMulti", 1.0, T)

func FreezeTime(EndT : float = 0.025, StartT : float = 0.25) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_method(UpdateTime, GameFrameTimeMulti, 0.0, EndT)
	tw.finished.connect(StartTime, StartT)

func UpdateTime(NewTime : float) -> void:
	GameFrameTimeMulti = NewTime
	get_tree().set_group("Particles", "speed_scale", GameFrameTimeMulti)
	MaterialAnimator.SpeedScale = NewTime
