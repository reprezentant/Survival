extends Panel

@onready var label = $HBoxContainer/Label
@onready var icon = $HBoxContainer/Icon



# Pokazuje powiadomienie o podniesieniu przedmiotu z ikoną
func show_notification(item_key, amount: int = 1):
	# Pobierz zasób przedmiotu
	var item_resource = ItemConfig.get_item_resource(item_key)
	# Ustaw tekst zawsze z ilością
	label.text = "Zebrałeś: %s x%d" % [item_resource.display_name, amount]
	# Ustaw ikonę jeśli jest
	if item_resource.icon:
		icon.texture = item_resource.icon
	else:
		icon.texture = null
	show()
	# Animacja
	modulate = Color(1,1,1,0)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

func _ready():
	hide()
