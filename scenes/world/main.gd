extends Node2D


@export var end_screen: PackedScene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("reset"):
		get_tree().change_scene_to_packed(end_screen)
