extends BaseObstacle

@export var textures: Array[Texture2D]

func _ready() -> void:
	super._ready()
	if not textures.is_empty():
		sprite.texture = textures.pick_random()
