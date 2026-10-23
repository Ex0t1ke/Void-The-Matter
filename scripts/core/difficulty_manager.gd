class_name DifficultyManager
extends Node
## Менеджер сложности и спавна врагов в стиле Risk of Rain.
## Чем дольше длится забег, тем выше уровень угрозы и сильнее монстры.

signal time_updated(formatted_time: String, difficulty_name: String, progress_ratio: float)

var time_passed: float = 0.0

const DIFFICULTIES = [
	{"time": 0.0, "name": "ОЧЕНЬ ЛЕГКО", "color": Color(0.2, 0.9, 0.3)},
	{"time": 90.0, "name": "ЛЕГКО", "color": Color(0.5, 0.9, 0.2)},
	{"time": 210.0, "name": "СРЕДНЕ", "color": Color(0.95, 0.85, 0.2)},
	{"time": 360.0, "name": "ТЯЖЕЛО", "color": Color(1.0, 0.55, 0.1)},
	{"time": 540.0, "name": "ОЧЕНЬ ТЯЖЕЛО", "color": Color(1.0, 0.25, 0.15)},
	{"time": 750.0, "name": "БЕЗУМИЕ", "color": Color(0.85, 0.1, 0.4)},
	{"time": 1000.0, "name": "ХА-ХА-ХА...", "color": Color(0.9, 0.0, 0.0)}
]

var spawn_timer: float = 0.0
var base_spawn_interval: float = 4.5

var beetle_scene: PackedScene = preload("res://scenes/enemies/beetle.tscn")
var wisp_scene: PackedScene = preload("res://scenes/enemies/wisp.tscn")

var target_player: PlayerController


func _ready() -> void:
	_find_player()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is PlayerController:
		target_player = players[0]


func _process(delta: float) -> void:
	time_passed += delta
	spawn_timer += delta
	
	# Форматирование времени MM:SS
	var minutes = int(time_passed) / 60
	var seconds = int(time_passed) % 60
	var time_str = "%02d:%02d" % [minutes, seconds]
	
	# Текущая ступень сложности
	var current_diff_name = "ОЧЕНЬ ЛЕГКО"
	for d in DIFFICULTIES:
		if time_passed >= d["time"]:
			current_diff_name = d["name"]
			
	var max_time = 1000.0
	var ratio = clampf(time_passed / max_time, 0.0, 1.0)
	time_updated.emit(time_str, current_diff_name, ratio)
	
	# Спавн волн врагов
	var current_interval = maxf(1.8, base_spawn_interval - (time_passed * 0.003))
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()


func _spawn_enemy_wave() -> void:
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 22:
		return # Лимит мобов на сцене для плавной производительности
		
	var p_pos = target_player.global_position
	# Спавн в кольце вокруг игрока (радиус 18..30м)
	var angle = randf() * TAU
	var dist = randf_range(16.0, 28.0)
	var spawn_pos = p_pos + Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
	
	var enemy: EnemyBase
	if randf() < 0.6:
		enemy = beetle_scene.instantiate() as EnemyBase
	else:
		enemy = wisp_scene.instantiate() as EnemyBase
		spawn_pos.y += 3.5
		
	# Масштабирование силы врага по времени
	var scale_factor = 1.0 + (time_passed * 0.012)
	enemy.max_health *= scale_factor
	enemy.current_health = enemy.max_health
	enemy.damage *= scale_factor
	enemy.gold_reward = int(enemy.gold_reward * (1.0 + time_passed * 0.008))
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
