extends BaseObstacle

var rotation_speed = -80

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees += rotation_speed * delta
