extends Control

signal game_resumed


func _on_resume_pressed() -> void:
	game_resumed.emit()


func _on_e_stop_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene("main_menu")
