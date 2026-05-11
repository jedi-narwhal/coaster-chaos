@tool
extends Path2D

@export var x_offset := 0.0
@export var y_offset := 0.0
@export_tool_button("Move path") var button = move_path

func move_path() -> void:
	for i in curve.point_count:
		curve.set_point_position(i, 
		curve.get_point_position(i) + Vector2(x_offset, y_offset))
