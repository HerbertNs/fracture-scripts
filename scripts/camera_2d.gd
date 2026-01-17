extends Camera2D

@export_category("Follow Character")
@export var player : CharacterBody2D

@export_category("Camera smoothing")
@export var smoothing_enabled : bool
@export_range(1,10) var smoothing_distance : int = 8

@export_category("shaking")
@export  var random_strength: float = 30.0
@export var shakeFade : float = 5.0

var rng = RandomNumberGenerator.new()
var shakeStrength : float = 0.0

func apply_shake():
	shakeStrength = random_strength

func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shakeStrength,shakeStrength),rng.randf_range(-shakeStrength,shakeStrength) )
	 

func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("shake"):
	#	apply_shake()
		
	if shakeStrength > 0:
		shakeStrength = lerpf(shakeStrength,0,shakeFade * delta)
		offset = random_offset()
			
	var weight : float
	if player != null:
		var camera_position : Vector2
		if smoothing_enabled:
			weight = float( smoothing_distance ) / 100
			camera_position = lerp(global_position, player.global_position,weight)
		else:
			camera_position = player.global_position
			
		global_position = camera_position  # Removed .floor() to prevent micro-stutters

func _ready() -> void:
	add_to_group("player")
	if RoomChangeGlobal.Activate:
		global_position = RoomChangeGlobal.PlayerPos
		RoomChangeGlobal.Activate = false
