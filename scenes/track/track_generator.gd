extends Node2D

# Reversed because of how up direction works
enum Slope {
	DOWN = 1,
	FLAT = 0,
	UP = -1,
}

enum TrackObject {
	STATIC,
	MOVING,
	BOOST,
}

const MAX_DIST_APART = 6
const MAX_GENERATIONS = 100
const MIN_Y = -28
const MAX_Y = 8

@export var obstacle_scene: PackedScene = preload("res://scenes/track/obstacle.tscn")
@export var moving_obstacles: Array[PackedScene] = [
	preload("res://scenes/track/balloon.tscn"),
	preload("res://scenes/track/spiky_bubble.tscn"),
]
@export var boost_scene: PackedScene = preload("res://scenes/track/firework_boost.tscn")
@export var player: CharacterBody2D
@export var terrain_set: int = 0
@export var terrain: int = 0
@onready var main_scene: Node2D = $".."

var obstacle_container: Node2D

var VALID_SLOPES: Dictionary[int, Array] = {
	Slope.FLAT: [Slope.FLAT, Slope.DOWN, Slope.UP],
	Slope.UP: [Slope.FLAT, Slope.UP],
	Slope.DOWN: [Slope.FLAT, Slope.DOWN],
}

var obstacle_chance: float = 0.10
var boost_chance: float = 0.05
var moving_obstacle_chance: float = 0.05

var generate_amount: int = 40
var clean_distance: int = 40
var furthest_clean_x: int = -1
var furthest_x: Array[int] = [0, 0, 0]
var furthest_y: Array[int] = [0, MAX_DIST_APART, MAX_DIST_APART * 2]
var last_slope: Array[int] = [Slope.FLAT, Slope.FLAT, Slope.FLAT]


func _ready() -> void:
	obstacle_container = Node2D.new()
	obstacle_container.name = "Obstacles"
	main_scene.add_child.call_deferred(obstacle_container)


func _physics_process(_delta: float) -> void:
	var player_x: int = get_child(0).local_to_map(to_local(player.global_position)).x
	clean_old_tiles(player_x)
	for i in range(MAX_GENERATIONS):
		if furthest_x[0] >= player_x + generate_amount:
			break
		var prev_x: int = furthest_x[0]
		generate_tiles()
		if furthest_x[0] == prev_x:
			push_warning("did not generate any tiles")
			break

func generate_tiles() -> void:
	var cells: Array[Array] = [[], [], []]
	var obstacle_cooldown: int = 2

	for i in get_child_count():
		cells[i].append(Vector2i(furthest_x[i] - 1, furthest_y[i]))

	for x in range(furthest_x[0], furthest_x[0] + generate_amount):
		if obstacle_cooldown > 0:
			obstacle_cooldown -= 1
		for i in get_child_count():
			var valid_slopes: Array = VALID_SLOPES[last_slope[i]].duplicate()

			# Clamp between Y bounds
			if furthest_y[i] >= MAX_Y:	# Y too high means too low on map
				valid_slopes.erase(Slope.DOWN)
			if furthest_y[i] <= MIN_Y:	# Y too low means too high on map
				valid_slopes.erase(Slope.UP)

			# Remove slope option if too far from a track
			for neighbor in get_child_count():
				var distance: int = abs(furthest_y[i] - furthest_y[neighbor])
				if distance >= MAX_DIST_APART:
					if furthest_y[i] > furthest_y[neighbor]:
						valid_slopes.erase(Slope.DOWN)
					elif furthest_y[i] < furthest_y[neighbor]:
						valid_slopes.erase(Slope.UP)

			# Prevent overlapping tracks
			for neighbor in range(i):
				for slope in Slope.values():
					if furthest_y[i] + slope == furthest_y[neighbor]:
						valid_slopes.erase(slope)

			# If Slope.FLAT was removed, add it back so it doesn't crash
			if valid_slopes.is_empty():
				valid_slopes = [Slope.FLAT]

			var slope: int = valid_slopes.pick_random()
			var y: int = furthest_y[i] + slope
			if slope != Slope.FLAT:
				cells[i].append(Vector2i(x, furthest_y[i]))
			cells[i].append(Vector2i(x, y))
			
			if slope == Slope.FLAT and obstacle_cooldown == 0:
				if spawn_obstacle(i, x, y):
					obstacle_cooldown = 2
			
			furthest_y[i] = y
			last_slope[i] = slope

	for i in get_child_count():
		var track := get_child(i) as TileMapLayer
		track.set_cells_terrain_connect(cells[i], terrain_set, terrain)
		furthest_x[i] += generate_amount


## Might spawn a track object.
## If this successfully spawns an obstacle, returns [code]true[/code].
func spawn_obstacle(track_idx: int, x: int, y: int) -> bool:
	var weights = PackedFloat32Array([
		obstacle_chance, 
		moving_obstacle_chance,
		boost_chance,
	])
	var total_weight: float = 0.0
	for weight in weights:
		total_weight += weight
	weights.append(1.0 - total_weight)
	var idx = RandomNumberGenerator.new().rand_weighted(weights)
	var obstacle: Node2D
	match idx:
		TrackObject.STATIC:
			obstacle = obstacle_scene.instantiate()
		TrackObject.MOVING:
			obstacle = moving_obstacles.pick_random().instantiate()
		TrackObject.BOOST:
			obstacle = boost_scene.instantiate()
		_:
			return false

	var track: TileMapLayer = get_child(track_idx)

	var local_pos: Vector2 = track.map_to_local(Vector2i(x, y))
	var world_pos: Vector2 = track.to_global(local_pos)
	obstacle.global_position = world_pos - Vector2(0, track.tile_set.tile_size.y)

	obstacle_container.add_child(obstacle)
	return true


func clean_old_tiles(player_x: int) -> void:
	for x in range(furthest_clean_x, player_x - clean_distance):
		for y in range(MIN_Y, MAX_Y):
			for z in get_child_count():
				get_child(z).erase_cell(Vector2i(x, y))
	furthest_clean_x = player_x - clean_distance - 1
