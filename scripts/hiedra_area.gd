extends Interactable

func _ready() -> void:
	dialogue = load("res://dialogues/hiedra.dialogue")
	require_paso_cerrado = true
	use_hover_feedback = false
	interact_sound = load("res://audios/AMBIENTES Y SFX/FOLEYS FINALES/rama.ogg")
	super._ready()
