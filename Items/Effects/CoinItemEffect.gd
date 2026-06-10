extends ItemEffect

class_name CoinItemEffect

@export var CoinAmm : int = 10

func ApplyEffect(Data : Dictionary) -> void:
	#var Source = Data["Source"] as Item
	Inventory.Instance.AddGold(CoinAmm)
	MessageBox.RegisterEvent("Acquired {0} light essence".format([CoinAmm]))
	AudioManager.Instance.PlaySound(AudioManager.Sound.COINS)

func GetDescription() -> String:
	return "Acquire {0} light essence".format([CoinAmm])
	
