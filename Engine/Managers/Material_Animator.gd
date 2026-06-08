extends Node

class_name MaterialAnimator

@export var MatData : Array[MaterialAnimationData]

var d : float = 0.05

static var SpeedScale : float = 1.0

func _physics_process(delta: float) -> void:
	for g in MatData:
		var currentvalue = g.Mat.get(g.VarName)
		if (g.AnimationSpeed == 0):
			g.NewGeneratedValue += delta * 10 * SpeedScale
			g.Mat.set(g.VarName, g.NewGeneratedValue)
		else: 
			if (g.Random):
				if (is_equal_approx(currentvalue, g.NewGeneratedValue)):
					g.NewGeneratedValue = randf_range(g.MinRange, g.MaxRange)
			else:
				if (g.GoingUp):
					g.NewGeneratedValue = g.MaxRange
				else:
					g.NewGeneratedValue = g.MinRange
				if (currentvalue >= g.MaxRange):
					if (g.Loop):
						currentvalue = g.MinRange
					else:
						g.GoingUp = false
				else: if (currentvalue <= g.MinRange):
					g.GoingUp = true
			g.Mat.set(g.VarName, move_toward(currentvalue, g.NewGeneratedValue, (delta * g.AnimationSpeed) * SpeedScale))
