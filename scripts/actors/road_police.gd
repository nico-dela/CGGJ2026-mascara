extends NpcInteractable

## Guardia de ruta — distinto del comisario de la comisaría.

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "el guardia"
	dialogue = load("res://content/dialogue/road/road_police.dialogue")
	dialogue_observe = load("res://content/dialogue/road/road_police_observe.dialogue")
	super._ready()
