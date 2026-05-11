extends Node2D


@onready var score_label = $ScoreCanvas/ScoreLabel
@onready var pause_menu= $"Pause menu"
var paused= false

func _ready() -> void:
	AudioManager.change_music("game")
	ScoreManager.reset_score()
	ScoreManager.score_changed.connect(_on_score_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_pressed("reset"):
		SceneManager.change_scene("end_screen")
	
	if Input.is_action_pressed("pause"):
		print("The pause button was pressed!")
		SceneManager.change_scene("pause_menu")
		pauseMenu()

func _on_score_changed(score: int) -> void:
	score_label.text = "Score: " + str(score)
	
func pauseMenu():
	print("running pause")
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
		
	paused= !paused


	
