extends Node

var sprite_history: Array[Dictionary] = []
var trail_sprites: Array[AnimatedSprite2D] = []

@export var start_carts: int = 3
@export var cart_sprite: AnimatedSprite2D

# Number of delay frames for each cart
@export var cart_spacing: int = 30

func _ready() -> void:
	add_carts()

func add_carts() -> void:
	for i in range(start_carts):
		var trail_sprite := cart_sprite.duplicate()
		add_child(trail_sprite)
		trail_sprites.append(trail_sprite)

func _physics_process(_delta: float) -> void:
	# Add information about the front-most sprite into the history
	sprite_history.push_front({
		"position": cart_sprite.global_position,
		"rotation": cart_sprite.global_rotation,
		"frame": cart_sprite.frame,
	})
	
	var history_size: int = (trail_sprites.size()) * cart_spacing
	if sprite_history.size() > history_size:
		sprite_history.pop_back()

	# Trailing carts copy data from the history at a delay
	for i in trail_sprites.size():
		var delay: int = (i + 1) * cart_spacing
		if delay < sprite_history.size():
			var data: Dictionary = sprite_history[delay]
			trail_sprites[i].global_position = data["position"]
			trail_sprites[i].global_rotation = data["rotation"]
			trail_sprites[i].frame = data["frame"]
			trail_sprites[i].visible = true
		else:
			trail_sprites[i].visible = false
