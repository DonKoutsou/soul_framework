extends Node3D

class_name MonsterManager

var Manequins : Array[EnemyManequin]
var RealTimeManequins : Array[EnemyManequin]
var TurnBasedManequins : Array[EnemyManequin]
#var ProcecedManequins : Array[EnemyManequin]
var DissabledManequins : Array[EnemyManequin]

var PlayerPos : Vector3i
var LoadDist : int

signal MonsterMetPlayer(Group : MonsterGroup)

func Toggle(t) -> void:
	set_physics_process(t)

func PlayerMet(Group : MonsterGroup) -> void:
	MonsterMetPlayer.emit(Group)

func SetLoadDist(dist : int) -> void:
	LoadDist = dist * dist

func Update(delta: float) -> void:
	var playerMapPos = Helper.PlayerPositionToMap(PlayerPos)
	for g in Manequins:
		if (playerMapPos.distance_squared_to(Helper.PlayerPositionToMap(g.position)) < LoadDist):
			g.Update(delta, PlayerPos)
			g.Toggle(true)
		else:
			g.Toggle(false)
		
	for g in RealTimeManequins:
		g.UpdateAction(delta)
	#print("Updated {0} monsters".format([Updated]))

func TakeAction() -> void:
	var playerMapPos = Helper.PlayerPositionToMap(PlayerPos)
	for g in TurnBasedManequins:
		if (playerMapPos.distance_squared_to(Helper.PlayerPositionToMap(g.position)) < LoadDist):
			g.TakeAction()
		
func PlPositionChanged(Pos : Vector3) -> void:
	PlayerPos = Pos

func AddMonster(M : EnemyManequin) -> void:
	add_child(M)
	
	if (M.G.IsTurnBased()):
		TurnBasedManequins.append(M)
	else:
		RealTimeManequins.append(M)
		
	Manequins.append(M)
	
	M.Dissabled.connect(MonsterDissabled.bind(M))
	M.Respawned.connect(MonsterEneable.bind(M))
	M.EnemyMet.connect(PlayerMet)

func MonsterDissabled(M : EnemyManequin) -> void:
	DissabledManequins.append(M)
	Manequins.erase(M)
	TurnBasedManequins.erase(M)
	RealTimeManequins.erase(M)
	M.call_deferred("Toggle", false)

func MonsterEneable(M : EnemyManequin) -> void:
	if (!Manequins.has(M)):
		DissabledManequins.erase(M)
		
		if (M.G.IsTurnBased()):
			TurnBasedManequins.append(M)
		else:
			RealTimeManequins.append(M)
		
		Manequins.append(M)
