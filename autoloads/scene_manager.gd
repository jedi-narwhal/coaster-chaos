extends Node

var scenes := {
	"main_menu": preload("res://scenes/ui/main_menu.tscn"),
	"main": preload("res://scenes/world/main.tscn"),
	"end_screen": preload("res://scenes/ui/end_screen.tscn"),
	"procedural_test": preload("res://scenes/testing/procedural_generation.tscn"),
	"cross_test": preload("res://scenes/testing/crossover.tscn")
}

func change_scene(scene_name: String) -> void:
	if scene_name in scenes:
		get_tree().call_deferred("change_scene_to_packed", scenes[scene_name])
