extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/road_bag.dialogue")
	verb = "Mirar"
	interact_label = "el bolso"
	despawn_on_interact = false
	use_hover_feedback = true
	hover_scale_multiplier = 1.08
	super._ready()
