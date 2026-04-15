extends Camera2D

@onready var player: CharacterBody2D = $"../Player"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var player_x = player.global_position.x
	global_position = Vector2(player_x, global_position.y)
