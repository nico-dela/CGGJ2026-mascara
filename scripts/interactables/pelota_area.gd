extends Interactable

## Forest ball removed from hybrid design — football comes from the hawker after briefing.

func _ready() -> void:
	visible = false
	input_pickable = false
	monitoring = false
	monitorable = false
	can_observe = false
	can_take = false
	can_use = false
	queue_free()
