extends Node2D


func _on_timer_puerta_timeout() -> void:
	$"CamaraPuerta".enabled = false
	$"Player/Camera2D".enabled = true
