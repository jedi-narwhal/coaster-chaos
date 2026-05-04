extends Node

var scenes := {
	"main_menu": preload("res://scenes/ui/main_menu.tscn"),
	"main": preload("res://scenes/world/main.tscn"),
	"end_screen": preload("res://scenes/ui/end_screen.tscn"),
}

func change_scene(scene_name: String) -> void:
	get_tree().call_deferred("change_scene_to_packed", scenes[scene_name])
