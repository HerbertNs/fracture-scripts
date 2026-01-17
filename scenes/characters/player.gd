extends CharacterBody2D

const COYOTE_TIME: float = 0.1
var coyote_timer: float = 0.0
const JUMP_VELOCITY = -320.0

var escape_timer : float = 0.0
var escape_hold_time : float = 0.4

@export_category("PLAYER")
@export var gravity: float = 34.8
@export var SPEED = 195.0



@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_2d: Camera2D = $"../Camera2D"

var tween: Tween
var original_scale: Vector2
var is_squashing: bool = false

var entry_position : Vector2

func _ready():
	add_to_group("player")
	if RoomChangeGlobal.Activate:
		global_position = RoomChangeGlobal.PlayerPos
		if RoomChangeGlobal.PlayerJumpOnEnter:
			velocity.y = JUMP_VELOCITY
		RoomChangeGlobal.Activate = false
	
	entry_position = global_position
	
	#animaation scaling
	original_scale = animated_sprite_2d.scale
	tween = create_tween()
	tween.kill() 

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		# Reset scale 
		if not is_squashing:
			reset_scale()
	else:
		coyote_timer -= delta
		if velocity.y > 0 and not is_squashing:
			apply_stretch()
			
	velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		apply_squash()
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
	
	#if Input.is_action_just_pressed("restart"):
	#	get_tree().reload_current_scene()
	
		
	elif velocity.y < 0.0:
		if Input.is_action_just_released("jump"):
			velocity.y *= 0.4
			coyote_timer = 0.0
			
	var direction := Input.get_axis("left", "right")
	if direction > 0:
		animated_sprite_2d.flip_h = true
	elif direction < 0:
		animated_sprite_2d.flip_h = false
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
	
	if Input.is_action_pressed("quit"):
		escape_timer += delta
		if escape_timer >= escape_hold_time:
			get_tree().quit()
	else:
		escape_timer = 0.0
	
# Squash and stretching
func apply_squash():
	is_squashing = true
	tween = create_tween()
	tween.set_parallel(true)
	# Squash vertically, stretch horizontally
	tween.tween_property(animated_sprite_2d, "scale", 
	Vector2(original_scale.x * 1.15, original_scale.y * 0.84), 0.1)
	tween.tween_callback(reset_scale_after_squash).set_delay(0.1)

func reset_scale_after_squash():
	is_squashing = false
	tween = create_tween()
	tween.tween_property(animated_sprite_2d, "scale", original_scale, 0.2)

func apply_stretch():
	tween = create_tween()
	tween.set_parallel(true)
	# Stretch vertically, squash horizontally when falling
	tween.tween_property(animated_sprite_2d, "scale",
	 Vector2(original_scale.x * 0.8, original_scale.y * 1.2), 0.2)

func reset_scale():
	tween = create_tween()
	tween.tween_property(animated_sprite_2d, "scale", original_scale, 0.1)
