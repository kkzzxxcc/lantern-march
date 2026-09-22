extends Node

const SOUND_IDS := ["click", "summon", "hit", "ranged", "skill", "heal", "victory", "defeat"]
const MUSIC_IDS := ["menu", "battle"]
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var sounds: Dictionary = {}
var tracks: Dictionary = {}
var started := false
var music_context := "menu"
var last_played: Dictionary = {}

func _ready() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	# Stream playback mode retains Godot bus volume/mute on Web.
	music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		voices.append(player)
	for id in SOUND_IDS:
		sounds[id] = load("res://assets/audio/" + id + ".wav")
	for id in MUSIC_IDS:
		var stream: AudioStreamWAV = load("res://assets/audio/" + id + ".wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
		tracks[id] = stream
	apply_settings()

func _input(event: InputEvent) -> void:
	# First actual interaction unlocks Web audio, including keyboard/touch gameplay.
	if (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
		start_music()

func set_music_context(context: String) -> void:
	if not tracks.has(context):
		return
	if music_context == context and music.stream == tracks[context]:
		return
	music_context = context
	music.stop()
	music.stream = tracks[context]
	if started:
		music.play()

func start_music() -> void:
	if started:
		return
	started = true
	music.stream = tracks[music_context]
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
	for entry in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var index := AudioServer.get_bus_index(entry[0])
		var volume := float(settings[entry[1]])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, volume)))
		AudioServer.set_bus_mute(index, volume <= 0.0 or (entry[1] == "master" and settings.mute))

func shutdown() -> void:
	started = false
	if music != null:
		music.stop()
		music.stream = null
	for player in voices:
		player.stop()
		player.stream = null
	sounds.clear()
	tracks.clear()

func _exit_tree() -> void:
	shutdown()
