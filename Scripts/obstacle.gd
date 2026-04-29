extends Area2D

@export var score_manager: Control
@export var end_screen: PackedScene

@export var speed_reduction := 50.0 / 100.0 # First number is the percentage change
@export var score_decrement := 10

func _on_body_entered(body: Node2D) -> void:
	'''
	Removes -1 health from body if it collides
	with the obstacle.
	
	:param body: Should only be the player's Node2D
	'''

	# if health > 1 : remove -1 health
	if body.health() > 1:
		body.remove_health()
		body.speed -= body.speed * speed_reduction
		score_manager.mod_score(-1 * score_decrement)
	else: # else : jump to game over scene
		# for now this prints game over
		body.remove_health()
	
	call_deferred("queue_free")
