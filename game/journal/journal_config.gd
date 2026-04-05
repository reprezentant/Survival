class_name JournalConfig


enum Keys {
	# Items — basic materials and consumables
	Stick = 0, Stone = 1, Plant = 2, Mushroom = 3, Fruit = 4,
	Log = 5, Coal = 6, Flintstone = 7, RawMeat = 8, CookedMeat = 9,
	Rope = 14, Torch = 16,
	# Creatures
	Wolf = 100, Cow = 101,
	# Objects — tools, structures, and craftable items
	Tree = 200, CoalBoulder = 201, FlintstoneBoulder = 202,
	Axe = 203, Pickaxe = 204, Campfire = 205, Multitool = 206, 
	Tinderbox = 207, Tent = 208, Raft = 209,
}

enum State { UNKNOWN = 0, DISCOVERED = 1, TESTED = 2 }

enum Category { ITEMS = 0, CREATURES = 1, OBJECTS = 2 }

const CATEGORY_LABELS := {
	Category.ITEMS: "Items",
	Category.CREATURES: "Creatures",
	Category.OBJECTS: "Objects",
}


static func get_all_keys() -> Array:
	return [
		Keys.Stick, Keys.Stone, Keys.Plant, Keys.Mushroom, Keys.Fruit,
		Keys.Log, Keys.Coal, Keys.Flintstone, Keys.RawMeat, Keys.CookedMeat,
		Keys.Rope, Keys.Torch,
		Keys.Wolf, Keys.Cow,
		Keys.Tree, Keys.CoalBoulder, Keys.FlintstoneBoulder,
		Keys.Axe, Keys.Pickaxe, Keys.Campfire, Keys.Multitool, 
		Keys.Tinderbox, Keys.Tent, Keys.Raft,
	]


static func get_category(key: Keys) -> Category:
	if int(key) < 100: return Category.ITEMS
	if int(key) < 200: return Category.CREATURES  
	return Category.OBJECTS


static func get_keys_by_category(category: Category) -> Array:
	var filtered_keys: Array = []
	var all_keys = get_all_keys()
	
	for key in all_keys:
		if get_category(key) == category:
			filtered_keys.append(key)
	
	return filtered_keys


# Map ItemConfig.Keys to JournalConfig.Keys for discovery
static func map_item_key_to_journal_key(item_key: int) -> int:
	match item_key:
		10: return Keys.Axe           # ItemConfig.Keys.Axe -> JournalConfig.Keys.Axe
		11: return Keys.Pickaxe       # ItemConfig.Keys.Pickaxe -> JournalConfig.Keys.Pickaxe 
		12: return Keys.Campfire      # ItemConfig.Keys.Campfire -> JournalConfig.Keys.Campfire
		13: return Keys.Multitool     # ItemConfig.Keys.Multitool -> JournalConfig.Keys.Multitool
		15: return Keys.Tinderbox     # ItemConfig.Keys.Tinderbox -> JournalConfig.Keys.Tinderbox
		17: return Keys.Tent          # ItemConfig.Keys.Tent -> JournalConfig.Keys.Tent
		18: return Keys.Raft          # ItemConfig.Keys.Raft -> JournalConfig.Keys.Raft
		_: return item_key            # For items that have the same values (0-9, 14, 16)


static func get_title(key: Keys) -> String:
	match key:
		Keys.Stick:             return "Stick"
		Keys.Stone:             return "Stone"
		Keys.Plant:             return "Plant"
		Keys.Mushroom:          return "Mushroom"
		Keys.Fruit:             return "Fruit"
		Keys.Log:               return "Log"
		Keys.Coal:              return "Coal"
		Keys.Flintstone:        return "Flintstone"
		Keys.RawMeat:           return "Raw Meat"
		Keys.CookedMeat:        return "Cooked Meat"
		Keys.Axe:               return "Axe"
		Keys.Pickaxe:           return "Pickaxe"
		Keys.Campfire:          return "Campfire"
		Keys.Multitool:         return "Multitool"
		Keys.Rope:              return "Rope"
		Keys.Tinderbox:         return "Tinderbox"
		Keys.Torch:             return "Torch"
		Keys.Tent:              return "Tent"
		Keys.Raft:              return "Raft"
		Keys.Wolf:              return "Wolf"
		Keys.Cow:               return "Cow"
		Keys.Tree:              return "Tree"
		Keys.CoalBoulder:       return "Coal Boulder"
		Keys.FlintstoneBoulder: return "Flintstone Boulder"
	return "Unknown"


static func get_discovered_text(key: Keys) -> String:
	match key:
		Keys.Stick:             return "A dry branch fallen from a tree. Common across the island."
		Keys.Stone:             return "A rough stone. Found almost everywhere."
		Keys.Plant:             return "Fibrous plant growing along the ground."
		Keys.Mushroom:          return "A wild mushroom. Looks suspicious."
		Keys.Fruit:             return "A small wild berry. Looks edible."
		Keys.Log:               return "A heavy log that smells of fresh-cut wood."
		Keys.Coal:              return "A chunk of black coal, leaves marks on your hands."
		Keys.Flintstone:        return "Sharp-edged grey stone. Could be useful."
		Keys.RawMeat:           return "Freshly cut raw meat. Needs cooking."
		Keys.CookedMeat:        return "Warm, cooked meat. Smells good."
		Keys.Axe:               return "A handcrafted stone axe. Feels sturdy."
		Keys.Pickaxe:           return "A stone pickaxe. Heavy but solid."
		Keys.Campfire:          return "A ring of stones with burning wood."
		Keys.Multitool:         return "A crude but versatile tool made from several materials."
		Keys.Rope:              return "Braided rope made from plant fibres."
		Keys.Tinderbox:         return "A small box for starting fires."
		Keys.Torch:             return "A stick wrapped in rope, ready to ignite."
		Keys.Tent:              return "A rough shelter made of sticks and plants."
		Keys.Raft:              return "A large raft assembled from logs and rope."
		Keys.Wolf:              return "A grey wolf. Watching you with sharp eyes."
		Keys.Cow:               return "A passive cow, grazing peacefully."
		Keys.Tree:              return "A tall tree. Plenty of them on this island."
		Keys.CoalBoulder:       return "A dark rocky formation. Might contain coal."
		Keys.FlintstoneBoulder: return "A grey boulder with sharp, glassy edges."
	return ""


static func get_tested_text(key: Keys) -> String:
	match key:
		Keys.Stick:
			return "Used in almost every recipe: axe, pickaxe, campfire, torch, tent and more. Always collect."
		Keys.Stone:
			return "Essential for crafting. Combine with stick and rope to make an axe or pickaxe."
		Keys.Plant:
			return "Can be woven into rope (2 plants). Also required for tent construction."
		Keys.Mushroom:
			return "⚠ Warning: Eating this caused -10 HP but +15 energy. Toxic!\nGives energy but damages health. Use wisely."
		Keys.Fruit:
			return "Safe to eat. Restores +20 HP and +10 energy. Good for quick recovery."
		Keys.Log:
			return "Key material for building the raft. Chop trees with an axe to obtain logs."
		Keys.Coal:
			return "Required to craft multitool and tinderbox. Mine coal boulders with a pickaxe."
		Keys.Flintstone:
			return "Required for multitool and tinderbox. Mine flintstone boulders with a pickaxe."
		Keys.RawMeat:
			return "Cannot be eaten raw. Place on a lit campfire and cook it first."
		Keys.CookedMeat:
			return "Best food on the island. Restores +75 HP and +75 energy."
		Keys.Axe:
			return "Chops trees to get logs. Also effective in combat. Craft from stick, stone and rope."
		Keys.Pickaxe:
			return "Breaks coal and flintstone boulders. Cannot chop wood. Craft from stick, stone and rope."
		Keys.Campfire:
			return "Place it and interact to open the cooking menu. Cook raw meat here. Requires tinderbox to craft."
		Keys.Multitool:
			return "Required tool for crafting advanced items (tinderbox, raft). Keep it — it is not consumed by use."
		Keys.Rope:
			return "Used in nearly every recipe. Craft from 2 plants. Always keep a supply."
		Keys.Tinderbox:
			return "Required to craft campfire and torch. Without it, no fire. Requires multitool to craft."
		Keys.Torch:
			return "Provides light when equipped. Craft from stick and rope using a tinderbox."
		Keys.Tent:
			return "Interact to sleep inside. Sleeping skips to daytime and passively restores energy."
		Keys.Raft:
			return "Interact with the placed raft to escape the island. This is the goal."
		Keys.Wolf:
			return "Aggressive. Hunts the player on sight. Deals 20 damage per hit. Drops raw meat when killed."
		Keys.Cow:
			return "Passive. Flees when approached. Does not attack. Drops raw meat when killed."
		Keys.Tree:
			return "Chop with an axe to obtain logs. Leaves a stump. Multiple logs per tree."
		Keys.CoalBoulder:
			return "Mine with a pickaxe to obtain coal. Axes have no effect on it."
		Keys.FlintstoneBoulder:
			return "Mine with a pickaxe to obtain flintstone. Axes have no effect on it."
	return ""


static func get_icon(key: Keys) -> Texture2D:
	# For items that have ItemConfig equivalents, get their icon
	var item_config_key = _map_journal_key_to_item_key(int(key))
	if item_config_key >= 0:
		return ItemConfig.get_item_resource(item_config_key as ItemConfig.Keys).icon
	return null


# Map JournalConfig.Keys back to ItemConfig.Keys for icon retrieval
static func _map_journal_key_to_item_key(journal_key: int) -> int:
	match journal_key:
		Keys.Axe: return 10           # JournalConfig.Keys.Axe -> ItemConfig.Keys.Axe
		Keys.Pickaxe: return 11       # JournalConfig.Keys.Pickaxe -> ItemConfig.Keys.Pickaxe 
		Keys.Campfire: return 12      # JournalConfig.Keys.Campfire -> ItemConfig.Keys.Campfire
		Keys.Multitool: return 13     # JournalConfig.Keys.Multitool -> ItemConfig.Keys.Multitool
		Keys.Tinderbox: return 15     # JournalConfig.Keys.Tinderbox -> ItemConfig.Keys.Tinderbox
		Keys.Tent: return 17          # JournalConfig.Keys.Tent -> ItemConfig.Keys.Tent
		Keys.Raft: return 18          # JournalConfig.Keys.Raft -> ItemConfig.Keys.Raft
		_: 
			if journal_key < 100:  # Items that have the same values (0-9, 14, 16)
				return journal_key
	return -1  # No ItemConfig equivalent
