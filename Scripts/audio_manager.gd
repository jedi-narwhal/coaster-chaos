extends Node

@onready var AudioPlayerMusic: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(AudioPlayerMusic)
	AudioPlayerMusic.stream = preload("res://Audio/Music/Coaster Chaos.mp3")
	AudioPlayerMusic.play()
