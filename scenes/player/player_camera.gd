extends Camera2D

@onready var player: CharacterBody2D = $"../World/Player"

var follow_enabled = true

func _process(delta: float) -> void:
	if follow_enabled:
		global_position = global_position.lerp(player.global_position, delta * 3)
