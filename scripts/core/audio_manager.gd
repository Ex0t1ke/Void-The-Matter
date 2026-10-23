class_name AudioManager
extends Node
## Архитектура звука игры Risk of Void.
## Синглтон с пулом 3D и 2D плееров и безопасным воспроизведением (Graceful Fallback).

const POOL_SIZE_3D: int = 12
const POOL_SIZE_2D: int = 8

var _players_3d: Array[AudioStreamPlayer3D] = []
var _players_2d: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer

var _audio_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_ensure_bus("Music", "Master")
	_ensure_bus("SFX", "Master")
	
	# Создаем фоновый музыкальный плеер
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)
	
	# Создаем пул 3D плееров
	for i in range(POOL_SIZE_3D):
		var p3d: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		p3d.name = "AudioPlayer3D_%d" % i
		p3d.bus = "SFX"
		p3d.max_distance = 60.0
		p3d.unit_size = 10.0
		add_child(p3d)
		_players_3d.append(p3d)
		
	# Создаем пул 2D/UI плееров
	for i in range(POOL_SIZE_2D):
		var p2d: AudioStreamPlayer = AudioStreamPlayer.new()
		p2d.name = "AudioPlayer2D_%d" % i
		p2d.bus = "SFX"
		add_child(p2d)
		_players_2d.append(p2d)


func _ensure_bus(bus_name: String, send_to: String = "Master") -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)


func play_sfx(sound_name: String, world_pos: Vector3 = Vector3.ZERO) -> void:
	var stream: AudioStream = _get_or_load_stream("res://assets/audio/sfx/" + sound_name)
	if not stream:
		# Graceful fallback: если аудиофайла нет, не роняем игру
		return
		
	if world_pos != Vector3.ZERO:
		var p3d: AudioStreamPlayer3D = _get_free_3d_player()
		if p3d:
			p3d.global_position = world_pos
			p3d.stream = stream
			p3d.play()
	else:
		var p2d: AudioStreamPlayer = _get_free_2d_player()
		if p2d:
			p2d.stream = stream
			p2d.play()


func play_music(music_name: String) -> void:
	var stream: AudioStream = _get_or_load_stream("res://assets/audio/music/" + music_name)
	if not stream:
		return
	if _music_player:
		_music_player.stream = stream
		_music_player.play()


func _get_or_load_stream(path: String) -> AudioStream:
	if _audio_cache.has(path):
		return _audio_cache[path] as AudioStream
		
	# Проверяем расширения (.ogg, .wav, .mp3)
	var possible_paths: Array[String] = [path]
	if not path.ends_with(".wav") and not path.ends_with(".ogg") and not path.ends_with(".mp3"):
		possible_paths.append(path + ".ogg")
		possible_paths.append(path + ".wav")
		possible_paths.append(path + ".mp3")
		
	for p in possible_paths:
		if ResourceLoader.exists(p):
			var res: Resource = load(p)
			if res is AudioStream:
				_audio_cache[path] = res
				return res as AudioStream
				
	return null


func _get_free_3d_player() -> AudioStreamPlayer3D:
	for p in _players_3d:
		if not p.playing:
			return p
	# Если все заняты, переиспользуем первый
	return _players_3d[0] if not _players_3d.is_empty() else null


func _get_free_2d_player() -> AudioStreamPlayer:
	for p in _players_2d:
		if not p.playing:
			return p
	return _players_2d[0] if not _players_2d.is_empty() else null
