extends Control

class_name Inventory

#@export var CharacterSheetScene : PackedScene
#@export var InventoryContainerScene : PackedScene

@export_group("Nodes")
@export var Cont : InventoryContainer
#@export var CharacterSheetPlecement : Control
#@export var InventoryContainerPlecement : Control
#@export var SelectedItemNameLabel : Label
#@export var SelectedItemDescriptionLabel : RichTextLabel
#@export var GoldLabel : Label
#@export var ItemDescr : Control
@export var ItemOpts : ItemOptions
#@export var ItemModel : MeshInstance3D
#@export var camera_3d: Camera3D
#@export var weapon_preview_position: SubViewport
var CurrentShownWeapon : FightWeapon

@export_group("Recepies")
@export var CombinationPossibilities : Array[CombinationData]


@export_group("Settings")
@export var InventorySpace : int = 12

var InventoryContents : Array[Item]

var Containers : Array[InventoryContainer]

var GoldAmmount : int = 0

signal ItemUsed(It : Item)
signal ItemAdded(It : Item)
signal ItemRemoved(It : Item)

signal AssistanceItem(t : bool)
signal RequestClose
static var Instance : Inventory

var CurrentlySelectedContainer : InventoryContainer
var CurrentlyCombinedItem : Item

var CurrentlyShownItemCategory : ItemCategory = ItemCategory.NORMAL

var CurrentlyShownItem : Item
var CurrentlyShownIndex : int = 0

enum ItemCategory{
	NORMAL,
	WEAPON,
	CONSUMABLE,
	KEY
}

#func _physics_process(_delta: float) -> void:
	#var Mpos = get_local_mouse_position() - Vector2(ItemDescr.size.x,0)
	#var VPRect =  get_viewport().get_visible_rect()
	#var DistanceFromDown = VPRect.size.y - get_global_mouse_position().y
	#var Diff = ItemDescr.size.y - DistanceFromDown
	
	#if (Diff > 0):
		#ItemDescr.position = Mpos - Vector2(0,Diff)
	#else:
		#ItemDescr.position = Mpos
	

func AddGold(Amm : int) -> void:
	GoldAmmount += Amm
	#GoldLabel.text = ": {0}".format([GoldAmmount])

func RemoveGold(Amm : int) -> void:
	GoldAmmount -= Amm
	#GoldLabel.text = ": {0}".format([GoldAmmount])

func LoseHalfGold() -> void:
	GoldAmmount /= 2
	#GoldLabel.text = ": {0}".format([GoldAmmount])

func _ready() -> void:
	Instance = self
	#GoldLabel.text = ": {0}".format([GoldAmmount])
	UISoundMan.Instance.Refresh()

var CurrentlyScrolledLine : int = 0

#Effect application

func ApplyEffects(EffectTimming : ItemEffect.EffectTiming, Data : Dictionary) -> void:
	var ItemsUsed : Array[Item]
	
	if (Data.has("Monster")):
		var m = Data["Monster"] as MonsterGroup
		for g : ItemEffect in m.Mon.Effects:
			if (g.Timing == EffectTimming):
				var NewData = Data.duplicate()
				NewData["Monster"] = NewData["User"]
				NewData["User"] = m
				g.ApplyEffect(NewData)
	
	for g in InventoryContents:
		Data["Source"] = g
		var used : bool = false
		
		if (ItemsUsed.has(g) and g.ConsumeOnUse):
			continue
			
		ItemsUsed.append(g)
		for i in g.Effects:
			if (i.Timing == EffectTimming):
				i.ApplyEffect(Data)
				used = true
		if (used and g.ConsumeOnUse):
			RemoveItem(g)
			break

func ApplyEffectsOfItem(It : Item, EffectTimming : ItemEffect.EffectTiming, Data : Dictionary) -> void:
	Data["Source"] = It
	var Used : bool = false
	for i in It.Effects:
		if (i.Timing == EffectTimming and i.CanUse(Data)):
			i.ApplyEffect(Data)
			Used = true
	if (Used and It.ConsumeOnUse):
		RemoveItem(It)

func HasItem(It : Item) -> bool:
	return InventoryContents.has(It)

func RemoveKeyItem(KeyIt : KeyItem.KeyItemType) -> void:
	var It : KeyItem
	
	for g in InventoryContents.size():
		if (InventoryContents[g] is KeyItem):
			if (InventoryContents[g].Type == KeyIt):
				It = InventoryContents.pop_at(g)
				break
	
	for g in Containers:
		if (g.ContainedItem == It):
			g.queue_free()
			Containers.erase(g)
			break
	
	if (It.Type == KeyItem.KeyItemType.ASSIST_RING):
		AssistanceItem.emit(false)
	RearangeInventory()
	MessageBox.RegisterEvent("Lost : {0}".format([It.ItemName]))

func RemoveItem(It : Item) -> void:
	if (CurrentlyShownIndex == InventoryContents.find(It)):
		InventoryContents.erase(It)
		_on_options_next()
	else:
		InventoryContents.erase(It)

	for g in Containers:
		if (g.ContainedItem == It):
			if (g.Ammount > 1):
				g.UpdateAmm(false)
			else:
				g.queue_free()
				Containers.erase(g)
			break
	
	ItemRemoved.emit(It)
	if (It is KeyItem and It.Type == KeyItem.KeyItemType.ASSIST_RING):
		AssistanceItem.emit(false)
	RearangeInventory()
	MessageBox.RegisterEvent("Lost : {0}".format([It.ItemName]), true, true)
	

func HasKeyItem(KeyIt : KeyItem.KeyItemType) ->bool:
	for g in InventoryContents:
		if (g is KeyItem ):
			if (g.Type == KeyIt):
				return true
	return false

func AddItem(It : Item, Notify : bool = true) -> void:
	InventoryContents.append(It)
	
	ItemAdded.emit(It)
	if (It is KeyItem and It.Type == KeyItem.KeyItemType.ASSIST_RING):
		AssistanceItem.emit(true)
	
	if (Notify):
		MessageBox.RegisterEvent("Picked up : {0}".format([It.ItemName]), true, true)
		AudioManager.Instance.PlaySound(AudioManager.Sound.LEVELUP, -15)
	
	if (It.Stack):
		for g in Containers:
			if (g.ContainedItem == It):
				g.UpdateAmm(true)
				return
	
	if (InventoryContents.size() == 1):
		CurrentlyShownIndex = 0
		Cont.AddItem(It)
		Cont.SetAmm(1)
		ItemOpts.It = It

func WeaponItemEquipped(t : bool, W : WeaponItem) -> void:
	var ItContainer = FindItemContainer(W)
	ItContainer.ToggleEquipped(t)

func FindItemContainer(It : Item) -> InventoryContainer:
	for g in Containers:
		if (g.ContainedItem == It):
			return g
	return null

func RearangeInventory() -> void:
	#for g in Containers:
		#if (g.ContainedItem == null):
			#InventoryContainerPlecement.move_child(g, InventoryContainerPlecement.get_child_count())
	UpdateSelectedItem()

func UpdateSelectedItem() -> void:
	if (CurrentlySelectedContainer == null):
		return
	
	#ItemDescr.visible = CurrentlySelectedContainer.ContainedItem != null
	#SelectedItemNameLabel.visible = CurrentlySelectedContainer.ContainedItem != null
	#SelectedItemDescriptionLabel.visible = CurrentlySelectedContainer.ContainedItem != null
	#SelectedItemNameLabel.text = CurrentlySelectedContainer.ContainedItem.ItemName
	#var Desc = CurrentlySelectedContainer.ContainedItem.GetItemDesc()
	#if (CurrentlySelectedContainer.Ammount > 1):
	#	Desc += "\nAmmount: {0}".format([CurrentlySelectedContainer.Ammount])
	#SelectedItemDescriptionLabel.text = Desc
	#ItemDescr.size.y = 0


func ContainerUnselected(_Cont : InventoryContainer) -> void:
	#ItemModel.visible = false
	CurrentlySelectedContainer = null
	#ItemDescr.size.y = 0
	#SelectedItemNameLabel.visible = false
	#SelectedItemDescriptionLabel.visible = false
	#ItemDescr.visible = false


func ToggleInventoryUI(t : bool) -> void:
	visible = t
	CancelConbinations()

func UpdateVisibility() -> void:
	for g in Containers:
		g.visible = ShouldBeShown(g.ContainedItem)
		#g.call_deferred("Init")
		
func ShouldBeShown(It : Item) -> bool:
	if (It is UnlockItem or It is KeyItem):
		return CurrentlyShownItemCategory == ItemCategory.KEY or CurrentlyShownItemCategory == ItemCategory.NORMAL
	else: if (It is WeaponItem):
		return CurrentlyShownItemCategory == ItemCategory.WEAPON or CurrentlyShownItemCategory == ItemCategory.NORMAL
	else: if (It.Effects.size() > 0):
		return CurrentlyShownItemCategory == ItemCategory.CONSUMABLE or CurrentlyShownItemCategory == ItemCategory.NORMAL
	
	return CurrentlyShownItemCategory == ItemCategory.NORMAL

func _on_weapon_items_show_pressed() -> void:
	CurrentlyShownItemCategory = ItemCategory.WEAPON
	UpdateVisibility()

func _on_consumable_items_show_pressed() -> void:
	CurrentlyShownItemCategory = ItemCategory.CONSUMABLE
	UpdateVisibility()

func _on_key_items_show_pressed() -> void:
	CurrentlyShownItemCategory = ItemCategory.KEY
	UpdateVisibility()

func _on_all_items_show_pressed() -> void:
	CurrentlyShownItemCategory = ItemCategory.NORMAL
	UpdateVisibility()

func _on_options_combined(It: Item) -> void:
	#ItemOpts.visible = false
	if (CurrentlyCombinedItem):
		var Combo = FindRecepie([It, CurrentlyCombinedItem])
		CancelConbinations()
		if (Combo != null):
			RemoveItem(Combo.CombinationItem[0])
			RemoveItem(Combo.CombinationItem[1])
			AddItem(Combo.CombinationResault)
			MessageBox.RegisterEvent("Combined {0} with {1} and created {2}".format([Combo.CombinationItem[1].ItemName, Combo.CombinationItem[0].ItemName, Combo.CombinationResault.ItemName]))
		else:
			MessageBox.RegisterEvent("Can't combine items.")
	else:
		MessageBox.RegisterEvent("Marked {0} to be combined".format([It.ItemName]))
		CurrentlyCombinedItem = It
		Cont.ToggleCombination(true)
		#FindItemContainer(It).ToggleCombination(true)

func FindRecepie(Itms : Array[Item]) -> CombinationData:
	for g in CombinationPossibilities:
		if (g.CombinationItem.has(Itms[0]) and g.CombinationItem.has(Itms[1])):
			return g
	return null

func CancelConbinations() -> void:
	if (CurrentlyCombinedItem != null):
		Cont.ToggleCombination(false)
		#FindItemContainer(CurrentlyCombinedItem).ToggleCombination(false)
		CurrentlyCombinedItem = null

func _on_options_equipped(It: Item) -> void:
	ItemUsed.emit(It)
	#ItemOpts.visible = false
	CancelConbinations()


func _on_options_used(It: Item) -> void:
	ItemUsed.emit(It)
	#ItemOpts.visible = false
	CancelConbinations()
	if (It is WeaponItem):
		Cont.ToggleEquipped(It.WeaponsRes.Equipped)
	#RequestClose.emit()

func _on_options_next() -> void:
	CurrentlyShownIndex = wrap(CurrentlyShownIndex + 1, 0, InventoryContents.size())
	var it = InventoryContents[CurrentlyShownIndex]
	Cont.AddItem(it)
	
	Cont.SetAmm(InventoryContents.count(it))
	ItemOpts.It = it
	Cont.ToggleCombination(it == CurrentlyCombinedItem)
	
	if (it is WeaponItem):
		Cont.ToggleEquipped(it.WeaponsRes.Equipped)
		#It.WeaponsRes.OnWeaponEquiped.connect(WeaponItemEquipped.bind(It))
	else:
		Cont.ToggleEquipped(false)

func _on_options_prev() -> void:
	CurrentlyShownIndex = wrap(CurrentlyShownIndex - 1, 0, InventoryContents.size())
	var it = InventoryContents[CurrentlyShownIndex]
	Cont.AddItem(it)
	
	Cont.SetAmm(InventoryContents.count(it))
	ItemOpts.It = it
	Cont.ToggleCombination(it == CurrentlyCombinedItem)
	
	if (it is WeaponItem):
		Cont.ToggleEquipped(it.WeaponsRes.Equipped)
	else:
		Cont.ToggleEquipped(false)
		#It.WeaponsRes.OnWeaponEquiped.connect(WeaponItemEquipped.bind(It))
