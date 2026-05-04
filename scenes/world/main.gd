extends Node2D


@onready var score_label = $ScoreCanvas/ScoreLabel


func _ready() -> void:
	ScoreManager.score_changed.connect(_on_score_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("reset"):
		SceneManager.change_scene("end_screen")


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: " + str(score)
