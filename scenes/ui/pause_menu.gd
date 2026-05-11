extends Control

signal game_resumed

@onready var main = $"../../"
@onready var world := $"../../World"

func _on_resume_pressed() -> void:
	world.reparent(main)
	game_resumed.emit()


func _on_e_stop_pressed() -> void:
	get_tree().paused = false
	SceneManager.change_scene("main_menu")
