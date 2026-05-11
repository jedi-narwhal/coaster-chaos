extends Area2D

class_name Firework_Boost

@export var speed_mult := 1.1
@export var score_increment := 10


func _on_body_entered(body: Node2D) -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	body.speed = body.speed * speed_mult
	ScoreManager.mod_score(score_increment)
