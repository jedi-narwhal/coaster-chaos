extends Node2D


@onready var score_label = $UI/ScoreLabel
@onready var pause_menu = $UI/PauseMenu
@onready var controls_container = $UI/ControlsContainer
@onready var launch_operators = $World/LaunchOperators
@onready var player = $World/Player

@onready var pause_viewport = $UI/PauseMenu/TextureRect/SubViewportContainer/SubViewport
@onready var world = $World

func _ready() -> void:
	AudioManager.change_music("game")
	ScoreManager.reset_score()
	ScoreManager.score_changed.connect(_on_score_changed)
	pause_menu.game_resumed.connect(_on_game_resumed)
	fade_controls_text()
	player.op1 = launch_operators.get_node("Operator1")
	player.op2 = launch_operators.get_node("Operator2")
	player.op3 = launch_operators.get_node("Operator3")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		SceneManager.change_scene("end_screen")
	if event.is_action_pressed("pause"):
		get_tree().paused = true
		world.reparent(pause_viewport)
		$UI/PauseMenu/TextureRect/SubViewportContainer/SubViewport/Camera2D.transform = player.get_node("Camera2D").transform
		pause_menu.visible = true


func _on_game_resumed() -> void:
	get_tree().paused = false
	pause_menu.visible = false


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: " + str(score)


func fade_controls_text() -> void:
	await get_tree().create_timer(5.0).timeout
	var tween = get_tree().create_tween()
	for label in controls_container.get_children():
		tween.parallel().tween_property(label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1)
