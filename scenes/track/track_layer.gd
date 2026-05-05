extends TileMapLayer

@export var player: CharacterBody2D
@export var terrain_set: int = 0
@export var terrain: int = 0

const MAX_GENERATIONS = 100

enum Slope {
	DOWN = -1,
	FLAT = 0,
	UP = 1,
}

var VALID_CHANGE: Dictionary[int, Array] = {
	Slope.FLAT: [Slope.DOWN, Slope.FLAT, Slope.UP],
	Slope.UP: [Slope.FLAT, Slope.UP],
	Slope.DOWN: [Slope.DOWN, Slope.FLAT],
}

var generate_amount: int = 20
var furthest_x: int = 0
var furthest_y: int = 0
var last_slope: int = Slope.FLAT


func _physics_process(_delta: float) -> void:
	var player_x := local_to_map(to_local(player.global_position)).x
	for i in range(MAX_GENERATIONS):
		if furthest_x >= player_x + generate_amount:
			break
		var prev_x := furthest_x
		generate_tiles()
		if furthest_x == prev_x:
			push_warning("did not generate any tiles")

func generate_tiles() -> void:
	var cells: Array[Vector2i] = []
	for x in range(furthest_x, furthest_x + generate_amount):
		var slope: int = VALID_CHANGE[last_slope].pick_random()
		var y: int = furthest_y + slope
		if slope != Slope.FLAT:
			cells.append(Vector2i(x, furthest_y))
		cells.append(Vector2i(x, y))
		furthest_y = y
		last_slope = slope
	set_cells_terrain_connect(cells, terrain_set, terrain)
	furthest_x += generate_amount
