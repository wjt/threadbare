# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name CollectibleItem extends Node2D

## Overworld collectible that can be interacted with. When a player interacts
## with it, an [InventoryItem] is added to the [Inventory]

## [InventoryItem] provided by this collectible when interacted with.
@export var item: InventoryItem:
	set(new_value):
		item = new_value
		update_configuration_warnings()

@onready var interact_area: InteractArea = $InteractArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D


func _get_configuration_warnings() -> PackedStringArray:
	if not item:
		return ["item property must be set"]
	return []


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	interact_area.interaction_started.connect(self._on_interacted)


func _process(_delta: float) -> void:
	if item:
		sprite_2d.texture = item.texture()


## When interacted with, the collectible will display a brief animation
## and when that finishes, a new [InventoryItem] will be added to the
## [Inventory] and the interaction will have ended.
func _on_interacted(_from_right: bool) -> void:
	z_index += 1
	animation_player.play("collected")
	await animation_player.animation_finished

	GameState.add_collected_item(item)

	interact_area.end_interaction()

	queue_free()
