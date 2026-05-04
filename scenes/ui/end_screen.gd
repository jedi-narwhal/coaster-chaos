extends Control


func _on_button_pressed() -> void:
	SceneManager.change_scene("main")

func _on_button_2_pressed() -> void:
	SceneManager.change_scene("main_menu")
