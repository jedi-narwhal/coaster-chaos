extends Control


func _ready() -> void:
	AudioManager.change_music("main_menu")


func _on_play_button_pressed() -> void:
	SceneManager.change_scene("main")


func _on_options_button_pressed() -> void:
	pass


func _on_test_button_pressed() -> void:
	SceneManager.change_scene("procedural_test")
