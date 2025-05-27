# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends Node

## Emitted when a new item is collected, even if it wasn't added to the
## inventory due to it being already there.
signal item_collected(item: InventoryItem)

## Emitted when a item is consumed, causing it to be removed from the
## [member inventory].
signal item_consumed(item: InventoryItem)

## Emitted whenever the items in the inventory change, either by collecting
## or consuming an item.
signal collected_items_changed(updated_items: Array[InventoryItem])

## Global inventory, used to track the items the player obtains and that
## can be added to the loom.
@export var inventory: Array[InventoryItem] = []
@export var current_spawn_point: NodePath

## Set when the loom transports the player to a trio of Sokoban puzzles, so that
## when the player returns to Fray's End the loom can trigger a brief cutscene.
var incorporating_threads: bool = false


## Reset the [member inventory] when a quest starts.
func start_quest() -> void:
	inventory.clear()


## Add the [InventoryItem] to the [member inventory].
func add_collected_item(item: InventoryItem) -> void:
	if not item in inventory:
		inventory.append(item)
	item_collected.emit(item)
	collected_items_changed.emit(items_collected())


## Remove the [InventoryItem] from the [member inventory].
func remove_consumed_item(item: InventoryItem) -> void:
	inventory.erase(item)
	item_consumed.emit(item)
	collected_items_changed.emit(items_collected())


## Return all the items collected so far in the [member inventory].
func items_collected() -> Array[InventoryItem]:
	return inventory.duplicate()
