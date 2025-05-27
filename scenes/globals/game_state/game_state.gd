# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
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

const GAME_STATE_PATH := "user://game_state.cfg"
const INVENTORY_SECTION := "inventory"
const INVENTORY_ITEMS_AMOUNT_KEY := "amount_of_items_collected"
const QUEST_SECTION := "quest"
const QUEST_PATH_KEY := "resource_path"
const QUEST_CURRENTSCENE_KEY := "current_scene"
const QUEST_SPAWNPOINT_KEY := "current_spawn_point"

## Global inventory, used to track the items the player obtains and that
## can be added to the loom.
@export var inventory: Array[InventoryItem] = []
@export var current_spawn_point: NodePath

## Set when the loom transports the player to a trio of Sokoban puzzles, so that
## when the player returns to Fray's End the loom can trigger a brief cutscene.
var incorporating_threads: bool = false

var _state := ConfigFile.new()


func _ready() -> void:
	var err := _state.load(GAME_STATE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_error("Failed to load %s: %s" % [GAME_STATE_PATH, err])
	_restore()


func start_quest(quest: Quest) -> void:
	_do_clear_inventory()
	_update_inventory_state()
	_state.set_value(QUEST_SECTION, QUEST_PATH_KEY, quest.resource_path)
	_do_set_scene(quest.first_scene, ^"")
	_save()


## Set the scene path and [member current_spawn_point].
func set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	_do_set_scene(scene_path, spawn_point)
	_save()


## Set the scene path and [member current_spawn_point] without triggering a save.
func _do_set_scene(scene_path: String, spawn_point: NodePath = ^"") -> void:
	current_spawn_point = spawn_point
	_state.set_value(QUEST_SECTION, QUEST_CURRENTSCENE_KEY, scene_path)
	_state.set_value(QUEST_SECTION, QUEST_SPAWNPOINT_KEY, current_spawn_point)


## Add the [InventoryItem] to the [member inventory].
func add_collected_item(item: InventoryItem) -> void:
	inventory.append(item)
	item_collected.emit(item)
	collected_items_changed.emit(items_collected())
	_update_inventory_state()
	_save()


## Remove all [InventoryItem] from the [member inventory].
func clear_inventory() -> void:
	_do_clear_inventory()
	_update_inventory_state()
	_save()


## Remove all [InventoryItem] from the [member inventory] without triggering a save.
func _do_clear_inventory() -> void:
	for item: InventoryItem in inventory.duplicate():
		inventory.erase(item)
		item_consumed.emit(item)
	collected_items_changed.emit(items_collected())


## Return all the items collected so far in the [member inventory].
func items_collected() -> Array[InventoryItem]:
	return inventory.duplicate()


func _update_inventory_state() -> void:
	var amount: int = clamp(inventory.size(), 0, InventoryItem.ItemType.size())
	_state.set_value(INVENTORY_SECTION, INVENTORY_ITEMS_AMOUNT_KEY, amount)


func _restore() -> void:
	var amount_in_state: int = _state.get_value(INVENTORY_SECTION, INVENTORY_ITEMS_AMOUNT_KEY, 0)
	var amount: int = clamp(amount_in_state, 0, InventoryItem.ItemType.size())
	for index in range(amount):
		var item := InventoryItem.with_type(index)
		inventory.append(item)
	var scene_path: String = _state.get_value(QUEST_SECTION, QUEST_CURRENTSCENE_KEY, "")
	current_spawn_point = _state.get_value(QUEST_SECTION, QUEST_SPAWNPOINT_KEY, ^"")
	if scene_path:
		SceneSwitcher.change_to_file(scene_path)


func _save() -> void:
	var err := _state.save(GAME_STATE_PATH)
	if err != OK:
		push_error("Failed to save settings to %s: %s" % [GAME_STATE_PATH, err])
