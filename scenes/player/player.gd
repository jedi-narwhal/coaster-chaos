extends CharacterBody2D

const MIN_SPEED := 25.0
const MAX_SPEED := 100.0
const SWITCH_DURATION := 0.1

## Change this if a new track's height is taller
const MAX_TRACK_HEIGHT := 20
const ROTATION_SMOOTHING := PI * 2

## Change this to change how far up/down the cart can see
var switch_track_dist := 100

var current_tween: Tween = null

var forward_direction := Vector2.RIGHT
var floor_normal := Vector2.UP

var player_health := 3
var speed := 50.0
var speed_gain := 0.03

@onready var up_raycast: RayCast2D = $UpRayCast
@onready var down_raycast: RayCast2D = $DownRayCast
@onready var floor_raycast: RayCast2D = $CollisionShape2D/FloorRayCast
@onready var jump_up: AudioStreamPlayer = $JumpUpSound
@onready var jump_down: AudioStreamPlayer = $JumpDownSound
@onready var obstacle_hit: AudioStreamPlayer = $ObstacleHitSound

var on_track := false
var _switching_track := false


func _ready() -> void:
	up_raycast.target_position.y = -switch_track_dist
	down_raycast.target_position.y = switch_track_dist
	floor_raycast.target_position.y = $CollisionShape2D.shape.height / 2.0 + 2.0
	velocity = speed * forward_direction

func _physics_process(delta: float) -> void:
	# Rolling animation
	if velocity.length() > 0:
		$AnimatedSprite2D.play("rolling")
	
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
	
	# Apply gravity
	if not on_track:
		velocity += get_gravity() * delta
	else:
		forward_direction = _get_forward_direction()
		velocity = speed * forward_direction
		velocity += -floor_normal * 10
	
	speed += speed * speed_gain * delta
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	
	_rotate_children(delta)
	_handle_jumps()
	move_and_slide()
	queue_redraw()


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

func _handle_jumps() -> void:
	# Jump to higher track
	if Input.is_action_just_pressed("up") and up_raycast.is_colliding():
		var raw_pos := _get_raw_track_position(up_raycast)
		if raw_pos != Vector2.INF:
			jump_up.play()
			var expected_dir := _get_expected_forward_direction(raw_pos)
			if expected_dir != Vector2.INF:
				forward_direction = expected_dir
			var target_pos := _get_expected_track_position(raw_pos)
			if target_pos != Vector2.INF:
				_switch_to_track(target_pos)
				_force_rotate_children()

	# Drop to lower track
	if Input.is_action_just_pressed("down") and down_raycast.is_colliding():
		if down_raycast.get_collision_normal().y < 0:
			var raw_pos := _get_raw_track_position(down_raycast)
			if raw_pos != Vector2.INF:
				jump_down.play()
				var expected_dir := _get_expected_forward_direction(raw_pos)
				if expected_dir != Vector2.INF:
					forward_direction = expected_dir
				var target_pos := _get_expected_track_position(raw_pos)
				if target_pos != Vector2.INF:
					_switch_to_track(target_pos)
					_force_rotate_children()

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
	var surface_dir: Vector2 = -floor_normal
	var query := PhysicsRayQueryParameters2D.create(
		pos - surface_dir * MAX_TRACK_HEIGHT,
		pos + surface_dir * MAX_TRACK_HEIGHT
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

func _switch_to_track(target: Vector2) -> void:
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
	)

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
