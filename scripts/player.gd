extends CharacterBody2D

# --- Constants ---
const TILE_SIZE = 16.0
const MOVE_DURATION = 0.15 # Time in seconds to move one tile (adjust for speed)
const COLLISION_LAYER_INDEX = 4 # TileMap layers are 0-indexed, so Layer 5 is index 4.

# --- Variables ---
var is_moving = false
var target_position = Vector2.ZERO
var move_timer = 0.0

@onready var up_raycast = $UpRayCast2D
@onready var down_raycast = $DownRayCast2D
@onready var left_raycast = $LeftRayCast2D
@onready var right_raycast = $RightRayCast2D

func _ready():
	# Ensure the character starts perfectly aligned to the grid
	global_position = global_position.snapped(Vector2(TILE_SIZE/2, TILE_SIZE/2))
	target_position = global_position

func _physics_process(delta):
	if is_moving:
		# 1. Handle ongoing movement
		move_to_target(delta)
	else:
		# 2. Handle input and initiate new movement
		handle_input()
	pass 


func handle_input():
	# Get the raw input axes
	var vertical = Input.get_axis("move_up", "move_down")
	var horizontal = Input.get_axis("move_left", "move_right")
	
	var move_direction = Vector2(horizontal, vertical)
	
	# Prioritize one direction if both are pressed (e.g., up/down over left/right)
	if move_direction.x != 0 and move_direction.y != 0:
		if abs(move_direction.x) > abs(move_direction.y):
			move_direction.y = 0
		else:
			move_direction.x = 0
			
	if move_direction != Vector2.ZERO:
		# Check walkability using the direction
		if is_walkable(move_direction):
			# Calculate the potential new grid position only after passing the check
			var new_target = global_position + (move_direction.normalized() * TILE_SIZE)

			target_position = new_target
			is_moving = true
			move_timer = 0.0

func move_to_target(delta):
	move_timer += delta
	var progress = move_timer / MOVE_DURATION

	# Use lerp to smoothly move the character from its start position to the target position
	global_position = global_position.lerp(target_position, progress)

	if progress >= 1.0:
		# Movement is complete: snap to the final target to ensure perfect alignment
		global_position = target_position
		is_moving = false
		move_timer = 0.0

func is_walkable(move_direction: Vector2) -> bool:
	# 1. Determine which RayCast corresponds to the movement direction
	var raycast_to_check: RayCast2D = null

	if move_direction.x > 0:
		raycast_to_check = right_raycast
	elif move_direction.x < 0:
		raycast_to_check = left_raycast
	elif move_direction.y > 0:
		raycast_to_check = down_raycast
	elif move_direction.y < 0:
		raycast_to_check = up_raycast
		
	# Safety check (shouldn't happen if handle_input is correct)
	if raycast_to_check == null:
		return false

	# 2. Force the raycast to update its collision check
	# Note: collide_with_bodies() is an internal function for collision checks. 
	# The actual check happens when you call force_update() or when physics happens.
	raycast_to_check.force_raycast_update() 

	# 3. Check the result: is_colliding() returns true if a collision object was hit.
	# We return true (WALKABLE) if the RayCast is NOT colliding.
	return not raycast_to_check.is_colliding()
