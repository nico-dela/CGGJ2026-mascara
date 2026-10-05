extends Interactable

## Forest duck removed from hybrid design — optional gift from the fisherman.

func _ready() -> void:
	visible = false
	input_pickable = false
	monitoring = false
	monitorable = false
	can_observe = false
	can_take = false
	can_use = false
	queue_free()
