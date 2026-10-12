extends PanelContainer

class_name CommandLine

@export var Text : TextEdit
@export var StartingMen : bool

@export var CommandListConfiguration : Dictionary[PackedStringArray, String]

@export_group("Nodes")
@export var RecomendationParent : Control
@export var HistoryLabel : RichTextLabel

var Items : Array[Item]

static var instance : CommandLine
static var Typing : bool = false
static var History : PackedStringArray = []

var update : bool = false

func _process(_delta: float) -> void:
	if (update):
		UpdateText()
		update = false

var toggleTw : Tween
var prevMouseState : Input.MouseMode

func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("CommandLine")):
		if (toggleTw != null and toggleTw.is_valid()):
			toggleTw.kill()
		get_child(0).visible = false
		if (!visible):
			visible = true
			toggleTw = create_tween()
			toggleTw.tween_property(self, "size", Vector2(size.x, 250), 0.1)
			toggleTw.finished.connect(get_child(0).show)
			toggleTw.finished.connect(Focus)
			Typing = true
			$In.play()
			prevMouseState = Input.mouse_mode
			InputManager.ChangeMouse(Input.MOUSE_MODE_VISIBLE)
		else:
			toggleTw = create_tween()
			toggleTw.tween_property(self, "size", Vector2(size.x, 0), 0.1)
			toggleTw.finished.connect(hide)
			Typing = false
			$Out.play()
			InputManager.ChangeMouse(prevMouseState)

func UpdateText() -> void:
	var t : String = " \n \n \n \n \n \n \n \n \n \n \n"
	for g in History:
		t += "\n" + g
	HistoryLabel.text = t
	#$VBoxContainer/RichTextLabel.scroll_following

static func AddText(t : String) -> void:
	print(t)
	History.append(t)
	if (History.size() > 50):
		History.remove_at(0)
	if (is_instance_valid(instance)):
		instance.update = true

static func AddErr(t : String) -> void:
	printerr(t)
	var st = "[color=#f35033]{0}[/color]".format([t])
	History.append(st)
	if (History.size() > 50):
		History.remove_at(0)
	if (instance != null):
		instance.update = true

func _ready() -> void:
	#if (!OS.is_debug_build() or OS.get_name() != "Windows"):
		#queue_free()
		#return
	instance = self
	Typing = false
	visible = false
	set_physics_process(false)
	RefrshExistingItems()
	UpdateText()

func OnCommandEntered() -> void:
	var Command = Text.text
	
	if (Command.substr(Command.length() - 1, Command.length()) == "\n"):
		Command = Command.replace("\n", "")
		CommandLine.AddText(Command)
		var response = HandleCommand(Command)
		if (">" in response):
			response = response.substr(1, response.length())
			CommandLine.AddErr("ERROR: " + response)
		else:
			CommandLine.AddText(response)
			
		#if (StartingMen):
			#PopUpManager.GetInstance().DoFadeNotif(response, get_parent())
		#else:
			#PopUpManager.GetInstance().DoFadeNotif(response, null)
		
		Text.text = ""
	UpdateRecomendations()
	Text.set_caret_column(Text.text.length())

func Focus() -> void:
	Text.grab_focus()
	Text.clear()
	
func HandleCommand(Command : String) -> String:
	
	var CommandList = Command.split(" ")
	
	if (CommandList.size() == 0):
		return ">Error"
	
	for command in CommandListConfiguration:
		var Match : bool = false
		var commandToExecute : String = ""
		var currentCheckedWord = 0
		while currentCheckedWord < command.size():
			var typedWord = CommandList[currentCheckedWord]
			var currentCommandWord = command[currentCheckedWord]
			if (typedWord.to_lower() == currentCommandWord.to_lower()):
				currentCheckedWord += 1
				if (currentCheckedWord == command.size()):
					Match = true
			else:
				break
		
		if (!Match):
			continue
		
		commandToExecute = CommandListConfiguration[command]
		
		
		if (commandToExecute != ""):
			if (!has_method(commandToExecute)):
				continue
			
			var args : Array = []
			for g in range(currentCheckedWord, CommandList.size()):
				args.append(str_to_var(CommandList[g]))

			#if (get_method_argument_count(commandToExecute) != args.size()):
				#return "Missing arguments.\nFailed to call command"
			if (!DoArgumentMatch(commandToExecute, args)):
				return ">Error matching arguments"
			return callv(commandToExecute, args)
			#call(commandToExecute, args)
	
	#match firstword:
		#"prologue":
			#return HandlePrologueCommand(CommandList)
		#"inv":
			#return HandleInventoryCommand(CommandList)
		#"stat":
			#return HandleStatCommand(CommandList)
		#"loc":
			#return HandleLocationCommand(CommandList)
	
	return ">Couldnt match command"

func DoArgumentMatch(methodName : String, methodArgs : Array[Variant]) -> bool:
	var m = get_method_list()
	var matchingArguments : int = 0
	for method in m:
		var n = method["name"]
		var args = method["args"]
		
		if (n != methodName):
			continue
			
		var def : Array = method["default_args"]
		var incommingArgs = methodArgs.duplicate()
		var dif = args.size() - def.size()
		
		for arg in range(incommingArgs.size(), args.size()):
			var defaultIndex : int = arg - dif
			if (defaultIndex < 0):
				continue
			incommingArgs.append(def[defaultIndex])

		if (incommingArgs.size() != args.size()):
			continue
		
		for argumentIndex in args.size():
			var methodArgument = args[argumentIndex]
			var incommingArgument = incommingArgs[argumentIndex]
			var methodArgumentType = methodArgument["type"]
			var incommingArgumentType = typeof(incommingArgument)
			if (methodArgumentType == incommingArgumentType):
				matchingArguments += 1
		
		if (matchingArguments == incommingArgs.size()):
			return true

	return false

#func HandlePrologueCommand(Command) -> String:
	#if (Command.size() == 1):
		#StartPrologue.emit(false)
		#return "Starting Prologue"
	#
	#var customSeed : int = -1
	#if (Command.size() == 3):
		#customSeed = Command[2]
	#
	#match (Command[1].to_lower()):
		#"skip":
			#StartPrologue.emit(true, customSeed)
			#return "Starting Prologue\nSkipping Story"
	#
	#return ">Error Handling Location Command"


#func CardFightTypeSwitch(newType : Card_Fight.CardFightTurnType) -> String:
	#if (get_tree().get_nodes_in_group("CardFight").size() > 0):
		#return ">Can't change type of fight while a fight is happening"
	#if (newType > Card_Fight.CardFightTurnType.size()):
		#return ">Invalid type"
	#Card_Fight.TurnType = newType
	#return "Card fight turn type\nchanged to {0}".format([Card_Fight.CardFightTurnType.keys()[newType]])

func RefrshExistingItems() -> void:
	var DirsToExplore :Array[String] = ["res://Resources/Items"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					#print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					#print("Found file: " + file_name)
					if (file_name.ends_with(".tres")):
						var It = load(g + "/" + file_name)
						Items.append(It)
				
				file_name = dir.get_next()

var offset : Vector2

func OnMoveButtonDown() -> void:
	offset = get_global_mouse_position() - global_position
	set_physics_process(true)

func OnMoveButtonUp() -> void:
	set_physics_process(false)
	Focus()
	
func _physics_process(_delta: float) -> void:
	global_position = get_global_mouse_position() - offset

func OnCloseButtonPressed() -> void:
	Typing = false
	visible = false

func UpdateRecomendations() -> void:
	ClearRecomendations()
	if (Text.text.length() == 0):
		return
		#for g in CommandListConfiguration:
			#var commandText = ListToString(g)
			#var args = GetMethodArguments(CommandListConfiguration[g])
			#AddRecomendation(commandText + ListToString(args))
	else:
		var text = Text.text.to_lower().split(" ")
		var matchingCommandIndexes : Array[int] = []
		for textIndex in text.size():
			if (text[textIndex] == ""):
				continue
			var length = text[textIndex].length()
			for wordListIndex : int in CommandListConfiguration.size():
				var wordList = CommandListConfiguration.keys()[wordListIndex]
				if (wordList.size() - 1 < textIndex):
					continue
				var word = wordList[textIndex].to_lower().substr(0, length)
				if (word == text[textIndex]):
					if (!matchingCommandIndexes.has(wordListIndex)):
						matchingCommandIndexes.append(wordListIndex)
				else:
					matchingCommandIndexes.erase(wordListIndex)
		for command in matchingCommandIndexes:
			var list = CommandListConfiguration.keys()[command]
			var commandText = ListToString(list)
			var args = GetMethodArguments(CommandListConfiguration[list])
			AddRecomendation(commandText + ListToString(args))
				
func GetMethodArguments(methodName : String) -> PackedStringArray:
	var methods = get_method_list()
	var argList : PackedStringArray = []
	
	for g in methods:
		if (g["name"] == methodName):
			var args = g["args"]
			var def = g["default_args"]
			for argumentIndex in args.size():
				var ArgumentName : String = args[argumentIndex]["name"]
				var ArgumentType = args[argumentIndex]["type"]
				
				#check if defaults has a value
				var dif = args.size() - def.size()
				var defIndex = argumentIndex - dif
				if (def.size() > defIndex and defIndex >= 0):
					argList.append("({0}:{1} = {2})".format([ArgumentName, type_string(ArgumentType), def[defIndex]]))
				else:
					argList.append("({0}:{1})".format([ArgumentName, type_string(ArgumentType)]))
	return argList

func ListToString(list : PackedStringArray) -> String:
	var finalString : String = ""
	for g in list:
		finalString += g + " "
	return finalString

func RecomendationPressed(text : String) -> void:
	Text.text = text + " "
	UpdateRecomendations()
	
func OnCommandLineFocused() -> void:
	UpdateRecomendations()
		
func AddRecomendation(RecText : String) -> void:
	var butn = Label.new()

	butn.autowrap_mode = TextServer.AUTOWRAP_WORD
	#butn.custom_minimum_size.x = RecomendationParent.size.x - 80
	#butn.connect("pressed", RecomendationPressed.bind(RecText))
	RecomendationParent.add_child(butn)
	butn.text = RecText

func ClearRecomendations() -> void:
	for g in RecomendationParent.get_children():
		g.queue_free()

################ FUNCTIONS ####################

func Freecam() -> String:
	Stage.ToggleFreecam()
	return "Freecam toggled"

func RespawnEnemies() -> String:
	Stage.CurrentWorld.MData.TimePassed(6)
	return "Enemies respawned"

func Shake(intentity : float = 0.02, duration : float = 0.3, red : bool = false, fov : bool = true) -> String:
	PlayerCamera.start_shake(intentity, duration, red, fov)
	return "Camera Shaken"

func NoClip(t : bool) -> String:
	BasePlayerManequin.Instance.NoClip = t
	return "Noclip = {0}".format([t])

func WaterWalk(t : bool) -> String:
	BasePlayerManequin.CanWalkOnWater = t
	if BasePlayerManequin.CanWalkOnWater:
		return "Can now walk on water"
	return "Can't walk on water"

func LavaWalk(t : bool) -> String:
	BasePlayerManequin.CanWalkOnLava = t
	if BasePlayerManequin.CanWalkOnLava:
		return "Can now walk on lava"
	return "Can't walk on lava"

func GapWalk(t : bool) -> String:
	BasePlayerManequin.CanWalkOverGaps = t
	if BasePlayerManequin.CanWalkOverGaps:
		return "Can now walk over gaps"
	return "Can't walk over gaps"

func RedoMap() -> String:
	Stage.CurrentWorld.RedoMap()
	return "Map Redone"

func SetHp(newValue : int) -> String:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.CurrentHP = newValue
	return "New HP = {0}".format([newValue])

func SetMana(newValue : int) -> String:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.CurrentMana = newValue
	return "New Mana = {0}".format([newValue])

func UpgradeHP() -> String:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_HP)
	return "HP Upgraded"

func UpgradeMana() -> String:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_MANA)
	return "Mana Upgraded"

func UpgradeStamina() -> String:
	var pl = get_tree().get_nodes_in_group("Player")[0] as Player
	pl.ControllingCharacter.UpgradeStat(CharacterStat.STATS.MAX_FATIGUE)
	return "Stamina Upgraded"
