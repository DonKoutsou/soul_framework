
extends Control
class_name MessageBox

static var TextContainer : Control

static var Events : Array[String]

static var Notifs : Array[Notification]

func _ready() -> void:
	TextContainer = $VBoxContainer

func Update(delta : float) -> void:
	for g in Notifs:
		g.Update(delta)

func _exit_tree() -> void:
	Notifs.clear()
	Events.clear()

static func RegisterEvent(EventText : String, Stack : bool = true, Important : bool = false) -> void:
	if (!Stack):
		if (Events.has(EventText)):
			return
		Events.append(EventText)
	var n = Notification.new()
	n.text = EventText
	n.add_theme_font_size_override("normal_font_size", 12)
	TextContainer.add_child(n)
	TextContainer.move_child(n, 0)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	n.bbcode_enabled = true
	n.clip_contents = false
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.Finished.connect(NotificationEnded.bind(EventText, n))
	Notifs.append(n)
	if (Important):
		n.modulate = Color(1,0,0)

static func NotificationEnded(EventText : String, notif : Notification) -> void:
	Events.erase(EventText)
	Notifs.erase(notif)
	#if (Events.size() > 0 and Events[Events.size() -1].substr(0, EventText.length()) == EventText):
		#var LastString = Events[Events.size() -1]
		#var dif = LastString.length() - EventText.length()
		#if (dif > 0):
			#var amm = str_to_var(LastString.substr(LastString.length() - dif + 3, dif - 4))
			#Events[Events.size() -1] = EventText + " (x{0})".format([amm + 1])
		#else:
			#Events[Events.size() -1] += " (x2)"
	#else:
		#Events.push_back(EventText)
	#if (Events.size() > 20):
		#Events.pop_front()
	#
	#var finaltext : String = ""
	#for g in Events.size():
		#finaltext += Events[g]
		#if (g < Events.size() -1):
			#finaltext += "[p]"
			#
	#TextContainer.text = finaltext
