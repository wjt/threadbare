# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name HookControl
extends Node2D
## @experimental
##
## Control for the grappling hook.
##
## Handles the input to control the aiming and throwing.
## This is a piece of the grappling hook mechanic.
## [br][br]
## The [b]ui_accept[/b] action is used for throwing.
## [br][br]
## The [b]ui_up, ui_down, ui_left and ui_right[/b] actions are used for aiming.
## Additionally, the mouse movement can also be used for aiming,
## but the mouse not considered the primary input.
## [br][br]
## Aiming is effectively rotating the [member ray_cast_2d].
## [br][br]
## Visually it displays the [member sprite_2d] texture pointing in the
## ray's direction.
## The arrow is semitransparent when the ray doesn't hit anything.
## [br][br]
## The [b]hook_listener[/b] group is notified by this control when throwing
## about the outcome of the throw: if an area was hooked, if it hit a wall
## or if it hit the air (hit nothing).
## The [b]hook_listener[/b] group is also notified when the control releases an
## area previously hooked.

## The control state.
enum State {
	## The control does not respond to user input and doesn't update.
	DISABLED,
	## The control responds to user input and updates.
	AIMING,
	## The control is temporarily paused from aiming. For example, while throwing.
	AIMING_PAUSED,
}

## How far a throw from this control can reach.
## This is the length of the [member ray_cast_2d].
@export_range(0.0, 500.0, 1.0, "or_greater") var string_length: float = 200.0:
	set(new_value):
		string_length = new_value
		ray_cast_2d.target_position = Vector2(string_length, 0)

## The current state. Starts disabled.
@export var state: State = State.DISABLED:
	set = _set_state

## The are currently hooked by this control.
var hooked_to: HookableArea

## True if the throw action is currently pressed.
var pressing_throw_action: bool = false

var _hook_angle: float

## The visual representation of the [member ray_cast_2d] direction.
## It also indicates if the ray is hitting a [HookableArea] by displaying
## the sprite solid, or semitransparent if not.
@onready var sprite_2d: Sprite2D = %Sprite2D

## The ray cast to handle collisions with hookable areas.
@onready var ray_cast_2d: RayCast2D = %RayCast2D


func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2

	if _event is InputEventMouseMotion:
		axis = get_global_mouse_position() - global_position
		if not axis.is_zero_approx():
			_hook_angle = axis.angle()
		return

	# When aiming with keyboard, do not change the hook angle if one of these actions was released.
	# This makes it possible to aim in diagonal directions.
	# Otherwise, if for example left and down are pressed to aim in diagonal and both are released,
	# there is always one that is released first so the aim direction ends up being either left or
	# down, not left AND down.
	if (
		_event.is_action_released(&"ui_left")
		or _event.is_action_released(&"ui_right")
		or _event.is_action_released(&"ui_up")
		or _event.is_action_released(&"ui_down")
	):
		return
	axis = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if not axis.is_zero_approx():
		if pressing_throw_action:
			_hook_angle = rotate_toward(_hook_angle, axis.angle(), 0.05)
		else:
			_hook_angle = axis.angle()

	if Input.is_action_just_pressed(&"ui_accept"):
		pressing_throw_action = true
		return

	if Input.is_action_just_released(&"ui_accept"):
		pressing_throw_action = false
		return


func _throw() -> void:
	if ray_cast_2d.is_colliding():
		if ray_cast_2d.get_collider() is HookableArea:
			hooked_to = ray_cast_2d.get_collider() as HookableArea
			if hooked_to.hook_control:
				hooked_to.hook_control.state = State.AIMING
				state = State.DISABLED
			get_tree().call_group(&"hook_listener", &"hooked", hooked_to)
		else:
			release()
			var wall_point := ray_cast_2d.get_collision_point()
			get_tree().call_group(&"hook_listener", &"hit_wall", wall_point)
			state = State.AIMING_PAUSED
	else:
		release()
		var air_point := global_position + Vector2(string_length, 0).rotated(_hook_angle)
		get_tree().call_group(&"hook_listener", &"hit_air", air_point)
		state = State.AIMING_PAUSED


## If an area is hooked, disconnect it.
func release() -> void:
	if hooked_to:
		get_tree().call_group(&"hook_listener", &"released", hooked_to)
		hooked_to = null


func _can_connect() -> bool:
	return ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() is HookableArea


func _set_state(new_state: State) -> void:
	state = new_state
	if not ready:
		return
	if state == State.DISABLED:
		rotation = 0
		pressing_throw_action = false
	if sprite_2d:
		sprite_2d.visible = state != State.DISABLED
	if ray_cast_2d:
		ray_cast_2d.enabled = state != State.DISABLED
	set_process_unhandled_input(state != State.DISABLED)


func _ready() -> void:
	_set_state(state)


func _process(_delta: float) -> void:
	if state == State.DISABLED:
		return
	rotation = _hook_angle
	sprite_2d.modulate = Color.WHITE if _can_connect() else Color(Color.WHITE, 0.5)
	if hooked_to:
		return
	if state != State.AIMING_PAUSED and pressing_throw_action:
		_throw()
