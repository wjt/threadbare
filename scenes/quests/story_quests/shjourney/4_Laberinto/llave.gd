extends Sprite2D

func CuandoEntraJugador(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.llaves += 1
		body.ActualizarLlaves()
		queue_free()
		if body.llaves == 3:
			$"../../CamaraPuerta".enabled = true
			$"../../Player/Camera2D".enabled = false
			$"../../TimerPuerta".start()
