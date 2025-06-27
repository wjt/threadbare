# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends AnimationPlayer

const BLOW_ANTICIPATION_TIME: float = 0.3

@onready var player: Player = owner
@onready var player_fighting: Node2D = %PlayerFighting

func _ready() -> void:
	player.mode_changed.connect(_on_player_mode_changed)

func _process(_delta: float) -> void:
	match player.mode:
		Player.Mode.COZY:
			_process_walk_idle(_delta)
		Player.Mode.FIGHTING:
			_process_fighting(_delta)

func _process_walk_idle(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play(&"idle")
	elif player.is_running():
		if has_animation("sprint"):
			play(&"sprint")
		else:
			play(&"walk")
	else:
		play(&"walk")

func _process_fighting(delta: float) -> void:
	if not player_fighting.is_fighting:
		if not (
			current_animation == &"blow" and current_animation_position > BLOW_ANTICIPATION_TIME
		):
			_process_walk_idle(delta)
		return

	

	if current_animation != &"blow":
		play(&"blow")
		seek(BLOW_ANTICIPATION_TIME, false, false)

func _on_player_mode_changed(mode: Player.Mode) -> void:
	match player.mode:
		Player.Mode.DEFEATED:
			play(&"defeated")
