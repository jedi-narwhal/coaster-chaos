class_name BaseObstacle
extends Area2D
## Base obstacle that removes player health on collision.
##
## When the player enters the [code]Area2D[/code], the obstacle
## removes 1 health and tweens this obstacle downward.

@export var speed_reduction := 0.25
@export var score_decrement := 10

@onready var sprite = $Sprite2D


func _ready() -> void:
	pass


## Removes 1 health when colliding with [param body], 
## which should only be the Player CharacterBody2D.
func _on_body_entered(body: Node2D) -> void:
	if body is not Player:
		return
	body.remove_health()
	$CollisionShape2D.set_deferred("disabled", true)
	body.speed -= body.speed * speed_reduction
	ScoreManager.mod_score(-1 * score_decrement)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(
		self,
		"global_position",
		global_position + Vector2(0, 150),
		1
	)
	tween.tween_callback(queue_free)
