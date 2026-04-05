extends VBoxContainer


@onready var energy_bar: TextureProgressBar = $EnergyBar
@onready var health_bar: TextureProgressBar = $HealthBar


func _enter_tree() -> void:
	# Use central connect_once to avoid duplicate connections across reloads
	EventSystem.connect_once("PLA_energy_updated", Callable(self, "update_energy"))
	EventSystem.connect_once("PLA_health_updated", Callable(self, "update_health"))


func update_energy(max_energy:float, current_energy:float) -> void:
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy


func update_health(max_health:float, current_health:float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
