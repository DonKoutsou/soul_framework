extends Projectile

class_name ItemProjectile

@export var It : Item

func CanShoot() -> bool:
	var Can = Inventory.Instance.HasItem(It)
	if (!Can):
		MessageBox.RegisterEvent("Missing {0}".format([It.ItemName]))
	return Can
