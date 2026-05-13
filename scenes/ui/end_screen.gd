extends Control

@onready var score_label = $Label


func _ready() -> void:
	ScoreManager.update_high_score()
	score_label.text = "you died :(\nhigh score: %d" % ScoreManager.high_score

func _on_button_pressed() -> void:
	SceneManager.change_scene("main")

func _on_button_2_pressed() -> void:
	SceneManager.change_scene("main_menu")
