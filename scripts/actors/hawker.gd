extends NpcInteractable

## Road hawker — seeds town mystery; gives football only after comisario briefing.

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "Vendedor ambulante"
	dialogue = load("res://content/dialogue/road/hawker.dialogue")
	dialogue_observe = load("res://content/dialogue/road/hawker_observe.dialogue")
	super._ready()

func get_verb_text() -> String:
	if Inventory.selected_item == "credencial":
		return tr("Usar %s con %s") % [Inventory.get_display_name("credencial"), get_interact_label()]
	return super.get_verb_text()

func _interact() -> void:
	var selected := Inventory.selected_item

	if selected == "credencial":
		dialogue_with_item = load("res://content/dialogue/road/hawker_credencial.dialogue")
		required_item = "credencial"
		super._interact()
		required_item = ""
		return

	dialogue = load("res://content/dialogue/road/hawker.dialogue")
	super._interact()
