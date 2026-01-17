extends Area2D
@onready var animation_player: AnimationPlayer = $ColorRect/AnimationPlayer
@onready var camera_2d: Camera2D = $Camera2D


func _on_body_entered(body: Node2D) -> void:
	#print("border touched")
	if body.is_in_group("player"):
		body.set_process_input(false)
		body.set_physics_process(false)
		#Engine.time_scale = 0.6
		
		var cameras = get_tree().get_nodes_in_group("player")
		for node in cameras:
			if node is Camera2D and node.has_method("apply_shake"):
				node.set_physics_process(true)
				node.apply_shake()
				Engine.time_scale = 1.0
				break
		#Engine.time_scale = 0.2
		
		animation_player.play("death_fade")
		await animation_player.animation_finished
		body.global_position = body.entry_position
		body.velocity = Vector2.ZERO
		animation_player.play("death_fade_out")
		
		body.set_process_input(true)
		body.set_physics_process(true)

func _ready() -> void:
	print("entered")
	animation_player.play("scene_entered")
