extends Node

@onready var AudioPlayerMusic: AudioStreamPlayer = AudioStreamPlayer.new()

var soundtracks: Dictionary = {
	"main_menu": null,
	"game": preload("res://assets/music/Coaster Chaos.mp3")
}

func _ready() -> void:
	add_child(AudioPlayerMusic)
	AudioPlayerMusic.stream = soundtracks["game"]
	AudioPlayerMusic.play()
