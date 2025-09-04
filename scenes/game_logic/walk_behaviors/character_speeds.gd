# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
class_name CharacterSpeeds
extends Resource
## @experimental
##
## Character movement speed parameters
##
## This resource holds speed parameters for character behaviors which enable walking or running,
## such as [InputWalkBehavior] and [FollowWalkBehavior]. Not all parameters are used by all
## behaviors.

## The character walking speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var walk_speed: float = 300.0

## The character running speed.
@export_range(10, 1000, 10, "or_greater", "suffix:m/s") var run_speed: float = 500.0

## How fast does the player transition from walking/running to stopped.
## A low value will make the character look as slipping on ice.
## A high value will stop the character immediately.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var stopping_step: float = 1500.0

## How fast does the player transition from stopped to walking/running.
@export_range(10, 4000, 10, "or_greater", "suffix:m/s²") var moving_step: float = 4000.0
