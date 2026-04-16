extends Camera2D

@onready var player: CharacterBody2D = $"../Player"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var player_x = player.global_position.x
	var player_y = player.global_position.y
	global_position = Vector2(player_x, player_y)
