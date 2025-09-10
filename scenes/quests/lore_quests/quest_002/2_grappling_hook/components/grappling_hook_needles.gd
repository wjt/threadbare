# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends Node2D
## Award button items when a loop is formed through the needles, and open the exit door.

@onready var door: Node2D = %Door
@onready var award_buttons: Node2D = %AwardButtons


func _ready() -> void:
	# When starting, hide and disable the button items to award so the player can't pick them:
	for c in award_buttons.get_children():
		c.process_mode = Node.PROCESS_MODE_DISABLED
		c.visible = false


func _award() -> void:
	# Remove the loop:
	var player: Player = get_tree().get_first_node_in_group("player")
	player.get_node("%PlayerHook").remove_string()

	# Show and enable the button items so the player can start picking them:
	for c in award_buttons.get_children():
		c.process_mode = Node.PROCESS_MODE_INHERIT
		c.visible = true

	# Wait before opening the door, to avoid multiple things happening at the same time:
	await get_tree().create_timer(1.0).timeout

	door.opened = true


func _on_all_hooked_all_hooked() -> void:
	_award()
