class_name StoneTitanBoss
extends EnemyBase
## Босс "Каменный Титан" (Stone Titan) — колосс планеты.
## Призывается активацией Телепорта. Обладает лазерным глазом и земляными ударами.

signal boss_health_updated(current: float, max_hp: float)
signal titan_slain()

var laser_timer: float = 3.5
var stomp_timer: float = 6.0
var is_channeling_laser: bool = false
var is_stomping: bool = false

var eye_light: OmniLight3D
var projectile_scene: PackedScene = preload("res://scenes/player/projectile.tscn")

var _titan_model: Node3D
var _titan_shoulders: Array[Node3D] = []
var _titan_legs: Array[Node3D] = []
var _titan_arms: Array[Node3D] = []
var _time_passed: float = 0.0


func _ready() -> void:
	super._ready()
	max_health = 1400.0
	current_health = 1400.0
	gold_reward = 150
	xp_reward = 250
	move_speed = 3.2
	damage = 25.0
	
	_setup_titan_model()
	boss_health_updated.emit(current_health, max_health)


func _setup_titan_model() -> void:
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").queue_free()
	if has_node("OmniLight3D"):
		get_node("OmniLight3D").queue_free()
		
	_titan_model = ProceduralModelBuilder.build_stone_titan()
	add_child(_titan_model)
	
	eye_light = _titan_model.get_node_or_null("EyeLight") as OmniLight3D
	
	for child in _titan_model.get_children():
		if child.name.begins_with("Shoulder"):
			_titan_shoulders.append(child as Node3D)
		elif child.name.begins_with("LegPivot"):
			_titan_legs.append(child as Node3D)
		elif child.name.begins_with("ArmPivot"):
			_titan_arms.append(child as Node3D)



func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	laser_timer = maxf(0.0, laser_timer - delta)
	stomp_timer = maxf(0.0, stomp_timer - delta)
	
	if is_channeling_laser or is_stomping:
		if not is_on_floor():
			velocity.y -= 30.0 * delta
		move_and_slide()
		return
		
	var dir: Vector3 = (target_player.global_position - global_position)
	dir.y = 0.0
	var dist: float = dir.length()
	
	# Преследование
	if dist > 8.0:
		var norm_dir: Vector3 = dir.normalized()
		velocity.x = norm_dir.x * move_speed
		velocity.z = norm_dir.z * move_speed
		look_at(global_position + norm_dir, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if stomp_timer <= 0.0:
			_stomp_attack()
			
	if not is_on_floor():
		velocity.y -= 30.0 * delta
		
	move_and_slide()
	
	_time_passed += delta
	var is_moving: bool = (velocity.x * velocity.x + velocity.z * velocity.z) > 0.1
	ProceduralAnimator.animate_titan(delta, _time_passed, is_moving, _titan_shoulders, _titan_legs, _titan_arms)

	
	# Запуск лазерной фазы
	if laser_timer <= 0.0 and not is_stomping:
		_fire_eye_laser()


func _stomp_attack() -> void:
	is_stomping = true
	stomp_timer = 6.5
	
	# Телеграфирование топота: подъем тела и замах руками-молотами
	var tween: Tween = create_tween()
	var orig_y: float = position.y
	for arm in _titan_arms:
		if is_instance_valid(arm):
			create_tween().tween_property(arm, "rotation:x", deg_to_rad(-65.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "position:y", orig_y + 1.8, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		for arm in _titan_arms:
			if is_instance_valid(arm):
				create_tween().tween_property(arm, "rotation:x", deg_to_rad(30.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	)
	tween.tween_property(self, "position:y", orig_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_execute_shockwave()
		for arm in _titan_arms:
			if is_instance_valid(arm):
				create_tween().tween_property(arm, "rotation:x", 0.0, 0.35)
		is_stomping = false
	)


func _execute_shockwave() -> void:
	if not is_instance_valid(target_player):
		return
	var dist: float = global_position.distance_to(target_player.global_position)
	# AoE урон в радиусе 14 метров, если игрок не увернулся или не подпрыгнул
	if dist <= 14.0:
		var height_diff: float = absf(target_player.global_position.y - global_position.y)
		var dmg_mult: float = 1.0 if height_diff > 2.2 else 1.8
		target_player.take_damage(damage * dmg_mult)


func _fire_eye_laser() -> void:
	is_channeling_laser = true
	laser_timer = 8.0
	
	# Зарядка лазерного ядра глаза
	if eye_light:
		var charge_tween: Tween = create_tween()
		charge_tween.tween_property(eye_light, "light_energy", 9.0, 0.6)
		charge_tween.tween_property(eye_light, "light_energy", 3.5, 0.3)
		
	# Серия лазерных снарядов с наведением
	var shoot_timer: SceneTreeTimer = get_tree().create_timer(0.6)
	shoot_timer.timeout.connect(func() -> void:
		if is_dead:
			is_channeling_laser = false
			return
		for i in range(6):
			var delay_timer: SceneTreeTimer = get_tree().create_timer(i * 0.14)
			delay_timer.timeout.connect(func() -> void:
				if not is_dead and is_instance_valid(target_player) and projectile_scene:
					var proj: Projectile = projectile_scene.instantiate() as Projectile
					if proj:
						get_parent().add_child(proj)
						var eye_pos: Vector3 = global_position + Vector3(0.0, 4.8, 0.0)
						proj.global_position = eye_pos
						var target_aim: Vector3 = target_player.global_position + Vector3(0.0, 0.9, 0.0)
						proj.direction = (target_aim - eye_pos).normalized()
						proj.speed = 46.0
						proj.damage = 11.0
						proj.scale = Vector3(1.4, 1.4, 1.4)
						proj.is_enemy_projectile = true
						proj.collision_mask = 3
			)
		var finish_timer: SceneTreeTimer = get_tree().create_timer(1.2)
		finish_timer.timeout.connect(func() -> void:
			is_channeling_laser = false
		)
	)


func take_damage(amount: float, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	boss_health_updated.emit(current_health, max_health)


func die() -> void:
	titan_slain.emit()
	super.die()
