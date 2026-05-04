extends Node

@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()

var soundtracks: Dictionary = {
	"main_menu": preload("res://assets/music/TitleScreen.mp3"),
	"game": preload("res://assets/music/Coaster Chaos.mp3")
}

func _ready() -> void:
	add_child(music_player)


func change_music(music_name: String) -> void:
	if music_name in soundtracks:
		music_player.stream = soundtracks[music_name]
		music_player.play()
