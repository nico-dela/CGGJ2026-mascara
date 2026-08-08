extends NpcInteractable

## Guardia de ruta — distinto del comisario de la comisaría.

func _ready() -> void:
	verb = "Hablar con"
	interact_label = "el guardia"
	dialogue = load("res://dialogues/road_police.dialogue")
	super._ready()
