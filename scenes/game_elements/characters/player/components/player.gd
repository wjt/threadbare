# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
class_name Player
extends CharacterBody2D

# 🔑 Llaves para abrir puerta
var llaves : int = 0
@export var llaves_maximas : int = 3
var puerta

signal mode_changed(mode: Mode)

## Controls how the player can interact with the world around them.
enum Mode {
	COZY,
	FIGHTING,
	DEFEATED,
}

const REQUIRED_ANIMATION_FRAMES: Dictionary[StringName, int] = {
	&"idle": 10,
	&"walk": 6,
	&"attack_01": 4,
	&"defeated": 11,
}
const DEFAULT_SPRITE_FRAME: SpriteFrames = preload("uid://vwf8e1v8brdp")

## Name for dialogue highlighting
@export var player_name: String = "Tim"

## Movement settings
@export var mode: Mode = Mode.COZY:
	set = _set_mode
@export_range(10, 100000, 10) var walk_speed: float = 300.0
@export_range(10, 100000, 10) var run_speed: float = 500.0
@export_range(10, 100000, 10) var stopping_step: float = 1500.0
@export_range(10, 100000, 10) var moving_step: float = 4000.0

## SpriteFrames with required animations
@export var sprite_frames: SpriteFrames = DEFAULT_SPRITE_FRAME:
	set = _set_sprite_frames

@export_group("Sounds")
@export var walk_sound_stream: AudioStream = preload("uid://cx6jv2cflrmqu"):
	set = _set_walk_sound_stream

var input_vector: Vector2

@onready var player_interaction: PlayerInteraction = %PlayerInteraction
@onready var player_fighting: Node2D = %PlayerFighting
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var _walk_sound: AudioStreamPlayer2D = %WalkSound

# ✅ Agregar al grupo y setear puerta al iniciar
func _ready() -> void:
	add_to_group("player")
	_set_mode(mode)
	_set_sprite_frames(sprite_frames)
	if get_parent().has_node("Puerta"):
		puerta = get_parent().get_node("Puerta")

# ✅ Actualizar llaves recogidas
func ActualizarLlaves():
	if llaves >= llaves_maximas:
		AbrirSalida()

func AbrirSalida():
	if puerta:
		puerta.queue_free()

# ✅ Movimiento
func _unhandled_input(_event: InputEvent) -> void:
	var axis: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var speed: float = run_speed if Input.is_action_pressed(&"running") else walk_speed
	input_vector = axis * speed

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if player_interaction.is_interacting or mode == Mode.DEFEATED:
		velocity = Vector2.ZERO
		return

	var step: float = stopping_step if input_vector.is_zero_approx() else moving_step
	velocity = velocity.move_toward(input_vector, step * delta)
	move_and_slide()

func is_running() -> bool:
	return input_vector.length_squared() > (walk_speed * walk_speed) + 1.0

# ✅ Combat / mode logic
func _set_mode(new_mode: Mode) -> void:
	var previous_mode: Mode = mode
	mode = new_mode
	if not is_node_ready():
		return
	match mode:
		Mode.COZY:
			_toggle_player_behavior(player_interaction, true)
			_toggle_player_behavior(player_fighting, false)
		Mode.FIGHTING:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, true)
		Mode.DEFEATED:
			_toggle_player_behavior(player_interaction, false)
			_toggle_player_behavior(player_fighting, false)
	if mode != previous_mode:
		mode_changed.emit(mode)

func _toggle_player_behavior(behavior_node: Node2D, is_active: bool) -> void:
	behavior_node.visible = is_active
	behavior_node.process_mode = (
		ProcessMode.PROCESS_MODE_INHERIT if is_active else ProcessMode.PROCESS_MODE_DISABLED
	)

func _set_sprite_frames(new_sprite_frames: SpriteFrames) -> void:
	sprite_frames = new_sprite_frames
	if not is_node_ready():
		return
	if new_sprite_frames == null:
		new_sprite_frames = DEFAULT_SPRITE_FRAME
	player_sprite.sprite_frames = new_sprite_frames
	update_configuration_warnings()

func _set_walk_sound_stream(new_value: AudioStream) -> void:
	walk_sound_stream = new_value
	if not is_node_ready():
		await ready
	_walk_sound.stream = walk_sound_stream

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray
	for animation in REQUIRED_ANIMATION_FRAMES:
		if not sprite_frames.has_animation(animation):
			warnings.append("sprite_frames is missing the following animation: %s" % animation)
		elif sprite_frames.get_frame_count(animation) != REQUIRED_ANIMATION_FRAMES[animation]:
			warnings.append(
				(
					"sprite_frames animation %s has %d frames, but should have %d"
					% [
						animation,
						sprite_frames.get_frame_count(animation),
						REQUIRED_ANIMATION_FRAMES[animation]
					]
				)
			)
	return warnings

# ✅ Teleport helper
func teleport_to(
	tele_position: Vector2,
	smooth_camera: bool = false,
	look_side: Enums.LookAtSide = Enums.LookAtSide.UNSPECIFIED
) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if is_instance_valid(camera):
		var smoothing_was_enabled: bool = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = smooth_camera
		global_position = tele_position
		%PlayerSprite.look_at_side(look_side)
		await get_tree().process_frame
		camera.position_smoothing_enabled = smoothing_was_enabled
	else:
		global_position = tele_position
