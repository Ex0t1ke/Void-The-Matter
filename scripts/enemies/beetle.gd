class_name BeetleEnemy
extends EnemyBase
## Враг "Жук" (Beetle) — роящийся монстр ближнего боя.
## Преследует игрока по земле и выполняет телеграфированную атаку с замахом.

var attack_cooldown: float = 0.0
var is_telegraphing: bool = false
var telegraph_timer: float = 0.0
const TELEGRAPH_DURATION: float = 0.38


var _beetle_legs: Array[Node3D] = []
var _time_passed: float = 0.0


func _ready() -> void:
	super._ready()
	max_health = 75.0
	current_health = 75.0
	move_speed = 5.6
	damage = 11.0
	gold_reward = 8
	xp_reward = 12
	
	_setup_beetle_model()


func _setup_beetle_model() -> void:
	# Удаляем временные примитивы если есть
	for c in ["MeshInstance3D", "HornL", "HornR"]:
		if has_node(c):
			get_node(c).queue_free()
			
	var model: Node3D = ProceduralModelBuilder.build_beetle()
	add_child(model)
	
	for child in model.get_children():
		if child.name.begins_with("Leg"):
			_beetle_legs.append(child as Node3D)



@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	
	if is_telegraphing:
		telegraph_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		if telegraph_timer <= 0.0:
			_execute_bite()
		if not is_on_floor():
			velocity.y -= 25.0 * delta
		move_and_slide()
		return
		
	var target_pos: Vector3 = target_player.global_position
	var move_target: Vector3 = target_pos
	
	if nav_agent:
		nav_agent.target_position = target_pos
		var next_nav_point: Vector3 = nav_agent.get_next_path_position()
		if not nav_agent.is_target_reached() and next_nav_point != Vector3.ZERO:
			move_target = next_nav_point
			
	var dir: Vector3 = (move_target - global_position)
	dir.y = 0.0
	var dist_to_player: float = (target_pos - global_position).length()
	
	if dist_to_player > 2.0:
		if dir.length_squared() > 0.04:
			var norm_dir: Vector3 = dir.normalized()
			velocity.x = norm_dir.x * move_speed
			velocity.z = norm_dir.z * move_speed
			look_at(global_position + norm_dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_cooldown <= 0.0:
			_start_telegraph()
			
	if not is_on_floor():
		velocity.y -= 25.0 * delta
		
	move_and_slide()
	
	_time_passed += delta
	var is_moving: bool = (velocity.x * velocity.x + velocity.z * velocity.z) > 0.1
	ProceduralAnimator.animate_beetle_legs(delta, _time_passed, is_moving, _beetle_legs)



func _start_telegraph() -> void:
	is_telegraphing = true
	telegraph_timer = TELEGRAPH_DURATION
	
	# Визуальное телеграфирование: приседание назад и пульсация
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.7, 1.2), TELEGRAPH_DURATION * 0.8)


func _execute_bite() -> void:
	is_telegraphing = false
	attack_cooldown = 1.4
	
	# Выпад вперед
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.9, 1.25, 1.1), 0.08)
	tween.tween_property(self, "scale", Vector3.ONE, 0.15)
	
	if is_instance_valid(target_player):
		var dist: float = global_position.distance_to(target_player.global_position)
		if dist <= 2.6:
			target_player.take_damage(damage)
