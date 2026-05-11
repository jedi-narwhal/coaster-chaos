extends CharacterBody2D

enum TrackLayer { ONE = 1, TWO = 2, THREE = 3 }

const MIN_SPEED := 25.0
const MAX_SPEED := 300.0
const SWITCH_DURATION := 0.1

## Change this if a new track's height is taller
const MAX_TRACK_HEIGHT := 16
const ROTATION_SMOOTHING := PI * 3
const START_SPEED = 50.0
const TRACK_LAYERS = [TrackLayer.ONE, TrackLayer.TWO, TrackLayer.THREE]

## Change this to change how far up/down the cart can see
var switch_track_dist := 100

var current_tween: Tween = null

var forward_direction := Vector2.RIGHT
var floor_normal := Vector2.UP

var player_health := 3
var speed := 1.0
var speed_gain := 0.03
var can_move := true

var on_track := false
var _switching_track := false
var launch := false

# These are set in-game
var op1: AnimatedSprite2D
var op2: AnimatedSprite2D
var op3: AnimatedSprite2D

@export var current_track_layer: int = TrackLayer.TWO
@onready var up_raycast: RayCast2D = $UpRayCast
@onready var down_raycast: RayCast2D = $DownRayCast
@onready var floor_raycast: RayCast2D = $CollisionShape2D/FloorRayCast
@onready var jump_up: AudioStreamPlayer = $JumpUpSound
@onready var jump_down: AudioStreamPlayer = $JumpDownSound
@onready var obstacle_hit: AudioStreamPlayer = $ObstacleHitSound

func _ready() -> void:
	up_raycast.target_position.y = -switch_track_dist
	down_raycast.target_position.y = switch_track_dist
	floor_raycast.target_position.y = $CollisionShape2D.shape.height / 2.0 + 4.0
	velocity = speed * forward_direction
	await get_tree().physics_frame
	_launch()


func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	# Rolling animation
	if velocity.length() > 0:
		$AnimatedSprite2D.play("rolling")
	
	if launch:
		return
	
	# Ignore physics if currently tweening
	if _switching_track:
		return

	var detected_normal := _get_floor_normal()
	if detected_normal != Vector2.INF:
		floor_normal = detected_normal
	else:
		floor_normal = Vector2.UP
	up_direction = floor_normal

	on_track = floor_raycast.is_colliding()

	# All tracks are collidable when not on track
	if not on_track:
		velocity += get_gravity() * delta
		_enable_all_track_layers()
	else:
		_disable_all_track_layers()
		if floor_raycast.get_collider() is TileMapLayer:
			var track := floor_raycast.get_collider()
			switch_track_layer(track)
		forward_direction = _get_forward_direction()
		velocity = speed * forward_direction
		velocity += -floor_normal * 20

	speed += speed * speed_gain * delta
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)

	_rotate_children(delta)
	move_and_slide()
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Jump to higher track
	if event.is_action_pressed("up") and up_raycast.is_colliding():
		var raw_pos := _get_raw_track_position(up_raycast)
		if raw_pos != Vector2.INF:
			jump_up.play()
			var expected_dir := _get_expected_forward_direction(raw_pos)
			if expected_dir != Vector2.INF:
				forward_direction = expected_dir
			var target_pos := _get_expected_track_position(raw_pos)
			if target_pos != Vector2.INF:
				_switch_to_track(target_pos, up_raycast.get_collider())
				_force_rotate_children()

	# Drop to lower track
	if event.is_action_pressed("down") and down_raycast.is_colliding():
		if down_raycast.get_collision_normal().y < 0:
			var raw_pos := _get_raw_track_position(down_raycast)
			if raw_pos != Vector2.INF:
				jump_down.play()
				var expected_dir := _get_expected_forward_direction(raw_pos)
				if expected_dir != Vector2.INF:
					forward_direction = expected_dir
				var target_pos := _get_expected_track_position(raw_pos)
				if target_pos != Vector2.INF:
					_switch_to_track(target_pos, down_raycast.get_collider())
					_force_rotate_children()


func _launch() -> void:
	launch = true
	if op1 and op2 and op3:
		op1.play("raise1")
		await op1.animation_finished
		op2.play("raise2")
		await op2.animation_finished
		op3.play("raise3")
		await op3.animation_finished
	
	speed = START_SPEED
	launch = false


## Rotates the floor normal and angle of the sprite and collision.
func _rotate_children(delta: float) -> void:
	if floor_normal == Vector2.INF:
		return
	var target_angle: float = floor_normal.angle() + PI / 2
	var smooth_angle := lerp_angle(
		$AnimatedSprite2D.global_rotation,
		target_angle,
		ROTATION_SMOOTHING * delta
	)
	$AnimatedSprite2D.global_rotation = smooth_angle
	$CollisionShape2D.global_rotation = smooth_angle


## Force rotates the floor normal and angle of the sprite and collision.
func _force_rotate_children() -> void:
	var target_angle: float = forward_direction.angle()
	$AnimatedSprite2D.global_rotation = target_angle
	$CollisionShape2D.global_rotation = target_angle


func _get_raw_track_position(raycast: RayCast2D) -> Vector2:
	var collision_point: Vector2 = raycast.get_collision_point()
	var collision_normal: Vector2 = raycast.get_collision_normal()
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state

	var result: Dictionary
	if collision_normal.y > 0:
		# Hit the underside, fire a ray from above to find the top surface
		var query := PhysicsRayQueryParameters2D.create(
			collision_point - Vector2(0, MAX_TRACK_HEIGHT),
			collision_point
		)
		query.exclude = [self]
		result = space_state.intersect_ray(query)
	else:
		# Hit a top surface, search further down for the next lower track
		var query := PhysicsRayQueryParameters2D.create(
			collision_point + Vector2(0, MAX_TRACK_HEIGHT),
			collision_point + Vector2(0, switch_track_dist)
		)
		query.exclude = [self]
		result = space_state.intersect_ray(query)

	if result:
		return result["position"]

	return Vector2.INF


func _get_expected_track_position(raw_pos: Vector2) -> Vector2:
	var half_cart_height: float = $CollisionShape2D.shape.height / 2.0
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		raw_pos - Vector2(0, MAX_TRACK_HEIGHT),
		raw_pos + Vector2(0, MAX_TRACK_HEIGHT)
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result:
		var surface_normal: Vector2 = result["normal"]
		var forward: Vector2 = speed * forward_direction * SWITCH_DURATION
		return forward + raw_pos + surface_normal * half_cart_height
	return Vector2.INF


func _get_expected_forward_direction(pos: Vector2) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		pos - Vector2(0, MAX_TRACK_HEIGHT),
		pos + Vector2(0, MAX_TRACK_HEIGHT)
	)
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return Vector2(-result["normal"].y, result["normal"].x)
	return Vector2.INF


func _get_floor_normal() -> Vector2:
	if floor_raycast.is_colliding():
		return floor_raycast.get_collision_normal()
	return Vector2.INF


func _get_forward_direction() -> Vector2:
	if floor_normal != Vector2.INF:
		return Vector2(-floor_normal.y, floor_normal.x)
	return forward_direction


func _switch_to_track(target: Vector2, collider: Node2D = null) -> void:
	_switching_track = true
	var expected_dir := _get_expected_forward_direction(target)
	var target_angle: float
	if expected_dir != Vector2.INF:
		target_angle = expected_dir.angle()
	else:
		target_angle = forward_direction.angle()
	current_tween = create_tween()
	current_tween.set_ease(Tween.EASE_OUT)
	current_tween.set_trans(Tween.TRANS_QUINT)
	current_tween.tween_property(self, "global_position", target, SWITCH_DURATION)
	current_tween.parallel().tween_property(
		$AnimatedSprite2D, "global_rotation", target_angle, SWITCH_DURATION
	)
	current_tween.parallel().tween_property(
		$CollisionShape2D, "global_rotation", target_angle, SWITCH_DURATION
	)

	current_tween.tween_callback(func():
		_switching_track = false
		velocity = speed * forward_direction
		if collider is TileMapLayer:
			switch_track_layer(collider)
		else:
			_enable_all_track_layers()
	)


func switch_track_layer(collider: TileMapLayer) -> void:
	set_collision_mask_value(current_track_layer, false)
	floor_raycast.set_collision_mask_value(current_track_layer, false)

	current_track_layer = _bitmask_to_layer(
		collider.tile_set.get_physics_layer_collision_layer(0)
	)

	set_collision_mask_value(current_track_layer, true)
	floor_raycast.set_collision_mask_value(current_track_layer, true)


func _bitmask_to_layer(bitmask: int) -> int:
	for i in range(32):
		if bitmask & (1 << i):
			return i + 1
	return 1


func _enable_all_track_layers() -> void:
	for layer in TRACK_LAYERS:
		set_collision_mask_value(layer, true)
		floor_raycast.set_collision_mask_value(layer, true)


func _disable_all_track_layers() -> void:
	for layer in TRACK_LAYERS:
		set_collision_mask_value(layer, false)
		floor_raycast.set_collision_mask_value(layer, false)


func _draw() -> void:
	if up_raycast.is_colliding():
		var up_pos := _get_raw_track_position(up_raycast)
		if up_pos != Vector2.INF:
			draw_line(up_raycast.position, to_local(up_pos), Color.RED, 1.0)
			draw_circle(to_local(up_pos), 2, Color.RED)
	if down_raycast.is_colliding():
		var down_pos := _get_raw_track_position(down_raycast)
		if down_pos != Vector2.INF:
			draw_line(up_raycast.position, to_local(down_pos), Color.BLUE, 1.0)
			draw_circle(to_local(down_pos), 2, Color.BLUE)


func _on_kill_plane_body_entered(_body: Node2D) -> void:
	SceneManager.change_scene("end_screen")


func get_health() -> int:
	return player_health


func remove_health() -> void:
	obstacle_hit.play()
	$CartTrail.on_player_health_lost()
	player_health -= 1
	if player_health <= 0:
		SceneManager.change_scene("end_screen")
