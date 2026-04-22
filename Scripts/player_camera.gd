extends Camera2D

@onready var player: CharacterBody2D = $"../Player"

func _process(delta: float) -> void:
	global_position = global_position.lerp(player.global_position, delta * 3)
