extends CanvasLayer

@onready var color_rect: ColorRect = $Fade

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color_rect.color.a = 0.0
	
func fade(target_alpha: float, duration: float = 1.0):
	color_rect.show()
	var tween = create_tween()
	
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", target_alpha, duration)

	return tween

func change_scene(path : String) -> void:	
	await fade(1.0, 2.0).finished
		
	get_tree().change_scene_to_file(path)
	
	await get_tree().process_frame
		
	await fade(0.0, 2.0).finished
