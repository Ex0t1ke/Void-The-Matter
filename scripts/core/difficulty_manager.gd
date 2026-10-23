class_name DifficultyManager
extends Node
## Менеджер сложности и спавна врагов в стиле Risk of Rain.
## Чем дольше длится забег, тем выше уровень угрозы и сильнее монстры.
## Обеспечивает честный спавн на дистанции >= 25м с визуальным лучом материализации.

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
var base_spawn_interval: float = 4.8
const INITIAL_GRACE_PERIOD: float = 5.0 ## Начальная пауза перед первой волной (сек)
const MIN_SPAWN_DIST: float = 25.0      ## Минимальная дистанция от игрока
const MAX_SPAWN_DIST: float = 42.0      ## Максимальная дистанция от игрока

var beetle_scene: PackedScene = preload("res://scenes/enemies/beetle.tscn")
var wisp_scene: PackedScene = preload("res://scenes/enemies/wisp.tscn")
var spawn_beam_scene: PackedScene = preload("res://scenes/vfx/spawn_beam.tscn")

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
	
	# Спавн волн врагов (с учетом начальной паузы)
	if time_passed < INITIAL_GRACE_PERIOD:
		return
		
	var current_interval = maxf(2.0, base_spawn_interval - (time_passed * 0.003))
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_spawn_enemy_wave()


func _spawn_enemy_wave() -> void:
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 24:
		return # Лимит мобов на сцене для стабильного фреймрейта
		
	var p_pos: Vector3 = target_player.global_position
	
	# Расчет безопасной позиции вне прямой зоны лица игрока:
	# Дистанция строго от 25м до 42м
	var dist: float = randf_range(MIN_SPAWN_DIST, MAX_SPAWN_DIST)
	
	# Определяем направление взгляда камеры игрока
	var forward: Vector3 = Vector3.FORWARD
	if is_instance_valid(target_player.camera_pivot):
		forward = -target_player.camera_pivot.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.01:
			forward = forward.normalized()
			
	# Смещаем спавн в боковые и задние полусферы (угол 45° .. 315° от направления камеры)
	var base_yaw: float = atan2(forward.x, forward.z)
	var offset_angle: float = randf_range(deg_to_rad(50.0), deg_to_rad(310.0))
	var final_angle: float = base_yaw + offset_angle
	
	var spawn_pos: Vector3 = p_pos + Vector3(sin(final_angle) * dist, 0.5, cos(final_angle) * dist)
	
	# Проверяем высоту рельефа под точкой спавна
	var terrain: Node = get_tree().root.find_child("IslandTerrain", true, false)
	if terrain and terrain.has_method("get_height_at"):
		spawn_pos.y = terrain.call("get_height_at", spawn_pos.x, spawn_pos.z) + 0.4
		
	# Спавним луч материализации
	if spawn_beam_scene:
		var beam: Node3D = spawn_beam_scene.instantiate() as Node3D
		if beam:
			get_parent().add_child(beam)
			beam.global_position = spawn_pos
			
	var enemy: EnemyBase
	if randf() < 0.65:
		enemy = beetle_scene.instantiate() as EnemyBase
	else:
		enemy = wisp_scene.instantiate() as EnemyBase
		spawn_pos.y += 3.5
		
	# Масштабирование характеристик по времени
	var scale_factor: float = 1.0 + (time_passed * 0.012)
	enemy.max_health *= scale_factor
	enemy.current_health = enemy.max_health
	enemy.damage *= scale_factor
	enemy.gold_reward = int(enemy.gold_reward * (1.0 + time_passed * 0.008))
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	
	# Плавное появление (материализация из луча)
	enemy.scale = Vector3(0.05, 0.05, 0.05)
	var tw: Tween = enemy.create_tween()
	tw.tween_property(enemy, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
