extends Control

@export var game_scene: PackedScene

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)


func _on_options_button_pressed() -> void:
	pass
