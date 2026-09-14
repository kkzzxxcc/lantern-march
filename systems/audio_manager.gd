extends Node

var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var sounds: Dictionary = {}
var started := false
var last_played: Dictionary = {}

func _ready() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		voices.append(player)
	for id in ["click", "summon", "hit", "skill", "victory", "defeat"]:
		var path: String = "res://assets/audio/" + id + ".wav"
		if ResourceLoader.exists(path):
			sounds[id] = load(path)
	apply_settings()

func start_music() -> void:
	if started:
		return
	started = true
	if ResourceLoader.exists("res://assets/audio/march.wav"):
		music.stream = load("res://assets/audio/march.wav")
		music.finished.connect(music.play)
		music.play()

func play(id: String) -> void:
	if not sounds.has(id):
		return
	var now := Time.get_ticks_usec()
	if now - int(last_played.get(id, -1000000)) < 60000:
		return
	last_played[id] = now
	var player := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	player.stream = sounds[id]
	player.play()

func apply_settings() -> void:
	var settings: Dictionary = Save.state.settings
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, settings.master)))
	AudioServer.set_bus_mute(0, settings.mute)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(0.0001, settings.music)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(0.0001, settings.sfx)))


func shutdown() -> void:
	if music != null:
		music.stop()
		music.stream = null
	for player in voices:
		player.stop()
		player.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
