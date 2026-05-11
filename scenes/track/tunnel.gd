extends Area2D

@export var next_scene_path: String

func _on_body_entered(body: Node2D) -> void:
	body.can_move = false

	#print("tunnel entered")
	var camera = get_viewport().get_camera_2d()
	
	camera.follow_enabled = false
	
	var tween = create_tween()
	tween.tween_property(camera, "global_position", global_position, 1.0)
	
	await tween.finished
	
	await TransitionManager.change_scene(next_scene_path)
	
	camera.follow_enabled = true
	body.can_move = true
