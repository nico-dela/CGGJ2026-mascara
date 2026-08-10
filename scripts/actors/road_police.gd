extends NpcInteractable

## Guardia de ruta — distinto del comisario de la comisaría.

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "Guardia"
	dialogue = load("res://content/dialogue/road/road_police.dialogue")
	dialogue_observe = load("res://content/dialogue/road/road_police_observe.dialogue")
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "credencial":
		return "Usar Credencial con Guardia"
	return super.get_verb_text()

func _interact() -> void:
	if Inventory.selected_item == "credencial":
		dialogue_with_item = load("res://content/dialogue/road/road_police_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return
	dialogue = load("res://content/dialogue/road/road_police.dialogue")
	super._interact()
