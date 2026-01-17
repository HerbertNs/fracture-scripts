extends CharacterBody2D

@export var small_bounce_strength: float = 30.0
@export var large_leap_strength: float = 50.0
@export var movement_range: float = 80.0

# Small horizontal movement properties
@export var max_horizontal_move: float = 15.0
@export var horizontal_move_chance: float = 0.3

@export var min_move_delay: float = 3.0
@export var max_move_delay: float = 5.5
@export var leap_chance: float = 0.08

@export var small_move_duration: float = 2.0
@export var large_move_duration: float = 8.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var original_position: Vector2 = Vector2.ZERO
var move_timer: float = 0.0
var next_move_time: float = 0.0
var tween: Tween

func _ready():
	original_position = position  # Use LOCAL position, not global
	tween = create_tween()
	reset_timer()
	animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	move_timer += delta
	
	if move_timer >= next_move_time and not tween.is_valid():
		start_smooth_movement()
		reset_timer()
	

func start_smooth_movement():
	var is_leap = randf() < leap_chance
	var strength = large_leap_strength if is_leap else small_bounce_strength
	var duration = large_move_duration if is_leap else small_move_duration

	var move_direction = -1.0 if randf() < 0.8 else 0.5  
	var move_distance = strength * move_direction
	
	# Calculate vertical target (relative to original LOCAL position)
	var target_y = original_position.y + clamp(move_distance, -movement_range, movement_range)
	var max_allowed_move = movement_range * 0.8
	target_y = clamp(target_y, original_position.y - max_allowed_move, original_position.y + max_allowed_move)
	
	# Calculate horizontal target (relative to original LOCAL position)
	var target_x = original_position.x
	if randf() < horizontal_move_chance:
		var horizontal_offset = randf_range(-max_horizontal_move, max_horizontal_move)
		target_x = original_position.x + horizontal_offset
	
	var target_position = Vector2(target_x, target_y)
	
	# Animation
	if move_direction < -0.5:
		animated_sprite.play("shootup")
	else:
		animated_sprite.play("idle")
	
	# Flip sprite based on horizontal direction
	if target_x > position.x:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true

	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	# Use LOCAL position for smooth movement
	tween.tween_property(self, "position", target_position, duration)
	
	# Return toward original LOCAL position
	tween.tween_property(self, "position", original_position, duration * 1.5)
	tween.tween_callback(return_to_idle)

func return_to_idle():
	animated_sprite.play("idle")

func reset_timer():
	move_timer = 0.0
	next_move_time = randf_range(min_move_delay, max_move_delay)
