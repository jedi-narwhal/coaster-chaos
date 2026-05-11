extends Control

@onready var main = $"../../"

func _on_resume_pressed() -> void:
	main.pause_menu()


func _on_e_stop_pressed() -> void:
	SceneManager.change_scene("main_menu")
