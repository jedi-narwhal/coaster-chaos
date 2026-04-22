extends Area2D

func _on_body_entered(body: Node2D) -> void:
	'''
	Removes -1 health from body if it collides
	with the obstacle.
	
	:param body: Should only be the player's Node2D
	'''

	# if health > 1 : remove -1 health
	if body.health() > 1:
		body.remove_health()
	else: # else : jump to game over scene
		# for now this prints game over
		body.remove_health()
		print("Game Over")
	
	queue_free()
