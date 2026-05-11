extends Node2D


@onready var score_label = $UI/ScoreLabel
@onready var pause_menu = $"UI/PauseMenu"

func _ready() -> void:
	AudioManager.change_music("game")
	ScoreManager.reset_score()
	ScoreManager.score_changed.connect(_on_score_changed)
	pause_menu.game_resumed.connect(_on_game_resumed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		SceneManager.change_scene("end_screen")
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		pause_menu.visible = true


func _on_game_resumed() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: " + str(score)
