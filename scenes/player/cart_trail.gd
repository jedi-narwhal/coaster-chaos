extends Node

var sprite_history: Array[Dictionary] = []
var trail_sprites: Array[AnimatedSprite2D] = []

## Number of trailing carts behind the player.
@export var cart_count: int = 2
@export var cart_sprite: AnimatedSprite2D
@export var player: CharacterBody2D

## Number of delay frames for each cart.
@export var cart_spacing: int = 30

func _ready() -> void:
	add_carts()

## Adds a trail of [param cart_count] carts behind the player.
func add_carts() -> void:
	for i in range(cart_count):
		var trail_sprite := cart_sprite.duplicate() as AnimatedSprite2D
		trail_sprite.top_level = true
		add_child(trail_sprite)
		trail_sprites.append(trail_sprite)

func _physics_process(_delta: float) -> void:
	cart_spacing = 1500 / player.speed
	# Add information about the front-most sprite into the history
	# Index 0 is the current cart, last index gets deleted
	sprite_history.push_front({
		"position": cart_sprite.global_position,
		"rotation": cart_sprite.global_rotation,
		"frame": cart_sprite.frame,
	})
	
	var history_size: int = trail_sprites.size() * cart_spacing + 1
	if sprite_history.size() > history_size:
		sprite_history.pop_back()

	# Trailing carts copy data from the history at a delay
	for i in trail_sprites.size():
		var delay: int = min((i + 1) * cart_spacing, sprite_history.size()-1)
		var data: Dictionary = sprite_history[delay]
		trail_sprites[i].global_position = data["position"]
		trail_sprites[i].global_rotation = data["rotation"]
		trail_sprites[i].frame = data["frame"]


func on_player_health_lost() -> void:
	if trail_sprites.is_empty():
		return
	
	var crashed := cart_sprite.duplicate() as AnimatedSprite2D
	crashed.top_level = true
	add_child(crashed)
	crashed.global_position = cart_sprite.global_position
	crashed.global_rotation = cart_sprite.global_rotation
	crashed.z_index -= 1
	var tween = crashed.create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(
		crashed,
		"global_position",
		crashed.global_position + Vector2(0, 150),
		1
	)
	tween.tween_callback(crashed.queue_free)
	
	if player.current_tween != null and player.current_tween.is_running():
		player.current_tween.kill()
	player._switching_track = false
	
	if cart_spacing >= sprite_history.size():
		return
	var data: Dictionary = sprite_history[cart_spacing]

	player.global_position = data["position"]
	player.reset_physics_interpolation() # this was frying me
	var target_rotation: float = data["rotation"]
	
	# Calculate new floor normal and forward direction
	var fn_angle: float = target_rotation - PI / 2.0
	player.floor_normal = Vector2(cos(fn_angle), sin(fn_angle))
	player.forward_direction = Vector2(
		-player.floor_normal.y, player.floor_normal.x
	)
	player.velocity = player.speed * player.forward_direction
	
	cart_sprite.global_rotation = target_rotation
	player.get_node("CollisionShape2D").global_rotation = target_rotation
	
	trail_sprites.pop_front().queue_free()
	
	# Removes first cart_spacing elements from sprite_history
	sprite_history = sprite_history.slice(cart_spacing)
	
	cart_count -= 1
