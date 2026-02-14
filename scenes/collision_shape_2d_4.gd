extends Node2D

@onready var collision_shape = $CollisionShape2D4
#@onready var sprite = $Sprite2D  # Si tienes un sprite que también quieras ocultar

func _ready():
	# Conectar la señal cuando el juego empieza
	GameManager.paso_abierto_signal.connect(_on_paso_abierto)
	
	# También podemos comprobar si ya estaba abierto de antes
	# (por si el jugador guardó/cargó partida después de abrirlo)
	if GameManager.is_paso_abierto():
		_on_paso_abierto()

func _on_paso_abierto():
	# Desactivar colisión
	collision_shape.disabled = true
	
	# Opcional: ocultar el sprite si hay uno
	#if sprite:
		#sprite.visible = false
	
	# Opcional: mostrar otro sprite (camino abierto)
	# $CaminoAbierto.visible = true
	
	print("Paso abierto - colisión desactivada")
