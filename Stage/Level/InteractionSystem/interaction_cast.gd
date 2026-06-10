extends RayCast3D

class_name InteractionCast

@export var InteractableTitleLabel : Label
@export var InteractableIndicator : TextureRect

static var CurrentInteractable : InteractionCollisionShape

static var Instance : InteractionCast

func _ready() -> void:
	Instance = self
	
func ToggleVisibility(t : bool) -> void:
	get_child(0).visible = t

func _physics_process(_delta: float) -> void:
	var Collided = is_colliding()
	var IsInteractable : bool
	
	
	if (Collided):
		var Area = get_collider() as Area3D
		IsInteractable = Area.get_collision_layer_value(8)
		if (IsInteractable):
			var CollisionShapeID = get_collider_shape()
			var ColliderOwnerID = Area.shape_find_owner(CollisionShapeID)
			var CollisionShape : CollisionShape3D = Area.shape_owner_get_owner(ColliderOwnerID)
			if (CollisionShape is InteractionCollisionShape):
				CurrentInteractable = CollisionShape
				if (CollisionShape.Name == InteractionCollisionShape.AreaNames.Lever):
					var LeverInfo = CollisionShape.LeverInfo
					
					var LeverText = "Lever\n"
					if (LeverInfo.Info.IsMissingPart):
						LeverText += "Dissabled"
					else: if (LeverInfo.State):
						LeverText += "On"
					else:
						LeverText += "Off"
					
					InteractableTitleLabel.text = LeverText
				else: if (CollisionShape.Name == InteractionCollisionShape.AreaNames.Door):
					var Dat = CollisionShape.DoorDat as DoorData
					var DoorText = "Door\n"
					if (Dat.LockDat != null):
						TutorialManager.Instance.PlayTextInstruction(TutorialManager.TutorialTypes.LOCKED_DOOR)
						DoorText += "Locked"
					InteractableTitleLabel.text = DoorText
					
				else: if (CollisionShape.Name == InteractionCollisionShape.AreaNames.Light_Door):
					var Dat = CollisionShape.DoorDat as LightDoorData
					var DoorText = "Light Door\n"
					DoorText += "Stored Light : {0}/50".format([roundi(Dat.StoredLight)])
					InteractableTitleLabel.text = DoorText
					
				else: if (CollisionShape.Name == InteractionCollisionShape.AreaNames.Projectile_Switch):

					var SwitchInfo = CollisionShape.SwitchInfo
					
					var SwitchText = "Switch\n"
					
					if (SwitchInfo.State):
						SwitchText += "On"
					else:
						SwitchText += "Off"
					
					InteractableTitleLabel.text = SwitchText
				else:
					var T : String = InteractionCollisionShape.AreaNames.keys()[CollisionShape.Name]
					InteractableTitleLabel.text = T.replace("_", " ")
			
				InteractableIndicator.scale = Vector2(1.0, 1.0)
				
			else:
				InteractableIndicator.scale = Vector2(0.68, 0.68)
				CurrentInteractable = null
				IsInteractable = false
		else:
			InteractableIndicator.scale = Vector2(0.68, 0.68)
	else:
		InteractableIndicator.scale = Vector2(0.68, 0.68)
		
	InteractableTitleLabel.visible = Collided and IsInteractable
