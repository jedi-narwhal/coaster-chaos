extends CharacterBody2D

const SPEED := 50.0
const SWITCH_DURATION := 0.2

# Change this if a new track's height is taller
const MAX_TRACK_HEIGHT := 20

# Change this to change how far up/down the cart can see
var switch_track_dist := 100

var forward_direction := Vector2.RIGHT

@onready var up_raycast: RayCast2D = $UpRayCast
@onready var down_raycast: RayCast2D = $DownRayCast

var _switching_track := false

func _ready() -> void:
	up_raycast.target_position.y = -switch_track_dist
	down_raycast.target_position.y = switch_track_dist
	velocity = SPEED * forward_direction

func _physics_process(delta: float) -> void:
	# Ignore physics if currently tweening
	if _switching_track:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity = SPEED * forward_direction
	
	_set_forward_direction()
	_rotate_children()
	_handle_jumps()
	move_and_slide()

func _rotate_children() -> void:
	if _get_floor_normal() == Vector2.INF:
		return
	var rotation_angle: float = _get_floor_normal().angle() + PI / 2
	$CollisionShape2D.global_rotation = rotation_angle
	up_raycast.global_rotation = rotation_angle
	down_raycast.global_rotation = rotation_angle

func _handle_jumps() -> void:
	var target_pos: Vector2
	
	# Jump to higher track
	if Input.is_action_just_pressed("up") and \
	is_on_floor() and up_raycast.is_colliding():
		target_pos = _get_track_position(up_raycast)
		if target_pos != Vector2.INF:
			_switch_to_track(target_pos)
	
	# Drop to lower track
	if Input.is_action_just_pressed("down") and \
	is_on_floor() and down_raycast.is_colliding():
		target_pos = _get_track_position(down_raycast)
		if target_pos != Vector2.INF:
			_switch_to_track(target_pos)

func _get_track_position(raycast: RayCast2D) -> Vector2:
	var collision_point: Vector2 = raycast.get_collision_point()
	var collision_normal: Vector2 = raycast.get_collision_normal()
	var half_cart_height: float = $CollisionShape2D.shape.extents.y
	
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var forward: Vector2 = SPEED * forward_direction * SWITCH_DURATION
	
	# hit underneath a track (normal is pointing downwards if positive y)
	# create a new raycast above the track to find the top of the rail
	if collision_normal.y > 0:
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			collision_point - MAX_TRACK_HEIGHT * collision_normal,
			collision_point
		)
		query.exclude = [self]
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			return forward + result["position"] + result["normal"] * half_cart_height
	else:
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			collision_point - MAX_TRACK_HEIGHT * collision_normal,
			collision_point - switch_track_dist * collision_normal,
		)
		query.exclude = [self]
		var result: Dictionary = space_state.intersect_ray(query)
		if result:
			return forward + result["position"] + result["normal"] * half_cart_height
	return Vector2.INF

func _get_floor_normal() -> Vector2:
	if down_raycast.is_colliding():
		return down_raycast.get_collision_normal()
	return Vector2.INF

func _set_forward_direction() -> void:
	var floor_normal: Vector2 = _get_floor_normal()
	if floor_normal != Vector2.INF:
		forward_direction = Vector2(-floor_normal.y, floor_normal.x)

func _switch_to_track(target: Vector2) -> void:
	_switching_track = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(
		self,
		"global_position",
		target,
		SWITCH_DURATION
	)
	
	# Return to normal physics on callback
	tween.tween_callback(func():
		_switching_track = false
		velocity = SPEED * forward_direction
	)
