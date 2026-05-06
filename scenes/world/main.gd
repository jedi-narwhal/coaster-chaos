extends Node2D


@onready var score_label = $ScoreCanvas/ScoreLabel


func _ready() -> void:
	AudioManager.change_music("game")
	ScoreManager.reset_score()
	ScoreManager.score_changed.connect(_on_score_changed)
	
	fade_controls_text()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("reset"):
		SceneManager.change_scene("end_screen")


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: " + str(score)


func fade_controls_text() -> void:
	await get_tree().create_timer(5.0).timeout
	var tween = get_tree().create_tween()
	tween.tween_property($ControlsCanvas/Label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1)
