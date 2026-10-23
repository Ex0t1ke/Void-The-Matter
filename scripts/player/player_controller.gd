class_name PlayerController
extends CharacterBody3D
## Контроллер Выжившего (Commando) в стиле Risk of Rain 2.
## Свободная 3D-камера от 3-го лица (Mouse Captured без ПКМ), процедурная анимация бега,
## динамический кувырок, стрельба из двух бластеров и прокачка предметов.

signal health_changed(current: float, max_hp: float)
signal gold_changed(amount: int)
signal xp_changed(current: int, needed: int, level: int)
signal skill_cooldown_updated(skill_name: String, ratio: float)
signal item_collected_banner(item: ItemData, total: int)

@export_group("Характеристики")
@export var base_speed: float = 7.5
@export var sprint_multiplier: float = 1.45
@export var base_jump_velocity: float = 11.5
@export var gravity: float = 26.0
@export var base_damage: float = 12.0
@export var mouse_sensitivity: float = 0.0022

@export_group("Ссылки на узлы")
@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var inventory: PlayerInventory
@export var blaster_left: Node3D
@export var blaster_right: Node3D
@export var visual_root: Node3D
@export var interact_raycast: RayCast3D

# Здоровье и экономика
var max_health: float = 110.0
var current_health: float = 110.0
var gold: int = 15
var xp: int = 0
var level: int = 1
var xp_needed: int = 25

# Таймеры и кулдауны способностей
var primary_cooldown: float = 0.0      ## ЛКМ: Очередь из бластеров
var base_primary_rate: float = 0.22    ## Базовое время между выстрелами
var secondary_cooldown: float = 0.0    ## ПКМ: Пробивающий выстрел
var utility_cooldown: float = 0.0      ## Shift: Тактический рывок
var special_cooldown: float = 0.0      ## Q: Граната

# Кувырок / Рывок
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD

# Камера и прицеливание
var camera_yaw: float = 0.0
var camera_pitch: float = -0.25
var anim_time: float = 0.0
var is_firing: bool = false
var air_jumps_used: int = 0


# Префабы снарядов и всплывающего урона
var projectile_scene: PackedScene = preload("res://scenes/player/projectile.tscn")
var damage_num_scene: PackedScene = preload("res://scenes/world/damage_number.tscn")

# Флаг поочередной стрельбы из левого/правого бластера
var fire_left: bool = false
var current_interactable: Node3D = null


func _ready() -> void:
	add_to_group("player")
	# Collision Layer 2 (Player = 2)
	collision_layer = 2
	# Collision Mask: Layer 1 (World=1) + Layer 3 (Enemies=4) + Layer 4 (Interactables=8) = 13
	collision_mask = 13
	
	# Настройка прижатия к полу
	floor_snap_length = 0.4
	floor_constant_speed = true
	floor_stop_on_slope = true
	
	# Свободный захват мыши при старте (без необходимости зажимать ПКМ!)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if camera_pivot:
		camera_pivot.rotation.y = camera_yaw
		camera_pivot.rotation.x = camera_pitch
		
	# Персонаж смотрит туда же, куда и камера (спиной к нам, лицом к прицелу)
	if visual_root:
		visual_root.rotation.y = camera_yaw

	if not inventory:
		inventory = $PlayerInventory if has_node("PlayerInventory") else PlayerInventory.new()
		if not has_node("PlayerInventory"):
			add_child(inventory)
			
	if not inventory.item_collected.is_connected(_on_item_collected):
		inventory.item_collected.connect(_on_item_collected)
		
	_setup_interaction_raycast()
	_setup_character_model()
	_recalculate_stats()
	current_health = max_health
	
	health_changed.emit(current_health, max_health)
	gold_changed.emit(gold)
	xp_changed.emit(xp, xp_needed, level)


var _commando_legs: Array[Node3D] = []
var _commando_arms: Array[Node3D] = []


func _setup_character_model() -> void:
	if not visual_root:
		return
	# Удаляем старые дочерние элементы если есть
	for child in visual_root.get_children():
		child.queue_free()
		
	var model: Node3D = ProceduralModelBuilder.build_commando()
	visual_root.add_child(model)
	model.position = Vector3.ZERO
	
	_commando_legs.clear()
	_commando_arms.clear()
	
	# Находим суставы для процедурной анимации
	var leg_l: Node3D = model.find_child("LegPivotL", true, false) as Node3D
	if not leg_l: leg_l = model.find_child("LegL", true, false) as Node3D
	if not leg_l: leg_l = model.find_child("Leg_L", true, false) as Node3D
	
	var leg_r: Node3D = model.find_child("LegPivotR", true, false) as Node3D
	if not leg_r: leg_r = model.find_child("LegR", true, false) as Node3D
	if not leg_r: leg_r = model.find_child("Leg_R", true, false) as Node3D
	
	var arm_l: Node3D = model.find_child("ArmPivotL", true, false) as Node3D
	if not arm_l: arm_l = model.find_child("ArmL", true, false) as Node3D
	if not arm_l: arm_l = model.find_child("Arm_L", true, false) as Node3D
	
	var arm_r: Node3D = model.find_child("ArmPivotR", true, false) as Node3D
	if not arm_r: arm_r = model.find_child("ArmR", true, false) as Node3D
	if not arm_r: arm_r = model.find_child("Arm_R", true, false) as Node3D
	
	if leg_l: _commando_legs.append(leg_l)
	if leg_r: _commando_legs.append(leg_r)
	if arm_l: _commando_arms.append(arm_l)
	if arm_r: _commando_arms.append(arm_r)
	
	# Привязываем спавн снарядов к стволам бластеров (MuzzleL и MuzzleR на -Z)
	var ml: Node3D = model.find_child("MuzzleL", true, false) as Node3D
	if not ml: ml = model.find_child("Muzzle_L", true, false) as Node3D
	var mr: Node3D = model.find_child("MuzzleR", true, false) as Node3D
	if not mr: mr = model.find_child("Muzzle_R", true, false) as Node3D
	
	if ml and mr:
		blaster_left = ml
		blaster_right = mr
	elif ml:
		blaster_left = ml
		blaster_right = ml
	else:
		var marker: Marker3D = Marker3D.new()
		marker.name = "MuzzleFallback"
		marker.position = Vector3(0.35, 0.92, -0.6)
		model.add_child(marker)
		blaster_left = marker
		blaster_right = marker


func _setup_interaction_raycast() -> void:
	if not interact_raycast and camera:
		interact_raycast = RayCast3D.new()
		interact_raycast.name = "InteractRayCast"
		interact_raycast.target_position = Vector3(0.0, 0.0, -9.0)
		interact_raycast.collision_mask = 9 # Layer 4 (8) + Layer 1 (1)
		interact_raycast.collide_with_areas = true
		interact_raycast.collide_with_bodies = true
		camera.add_child(interact_raycast)


func _input(event: InputEvent) -> void:
	if is_inside_tree() and get_tree().paused:
		return
	# Если курсор почему-то не захвачен (например, после клика по окну) — захватываем сразу
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Свободное вращение камеры движением мыши БЕЗ зажатия ПКМ
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-65.0), deg_to_rad(45.0))
		if camera_pivot:
			camera_pivot.rotation.y = camera_yaw
			camera_pivot.rotation.x = camera_pitch


func _physics_process(delta: float) -> void:
	anim_time += delta
	
	# 1. Регенерация здоровья
	if current_health < max_health:
		current_health = minf(max_health, current_health + (1.0 + level * 0.2) * delta)
		health_changed.emit(current_health, max_health)
		
	# 2. Обновление кулдаунов способностей
	_update_cooldowns(delta)
	
	# 3. Луч взаимодействия
	_check_interaction_ray()
	
	# 4. Рывок / Слайд (Тактический буст на джетпаке)
	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * (base_speed * 2.8)
		# Персонаж плавно парит над землёй (+0.15м) и наклоняется вперед (-Z)
		if visual_root:
			visual_root.position.y = 0.15
			visual_root.rotation.x = deg_to_rad(-16.0) # наклон вперед по ходу движения (-Z)
		if is_inside_tree():
			move_and_slide()
		if dash_timer <= 0.0:
			is_dashing = false
		return
	else:
		# Строгий гарантированный возврат в 0.0 при завершении рывка
		if visual_root:
			visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 8.0)
			visual_root.rotation.z = lerp_angle(visual_root.rotation.z, 0.0, delta * 12.0)
		
	# 5. Ввод перемещения (относительно камеры)
	var move_dir: Vector3 = _get_camera_move_dir()
	var is_moving: bool = move_dir.length_squared() > 0.01
	var is_sprinting: bool = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = inventory.get_move_speed(base_speed)
	if is_sprinting and is_moving:
		current_speed *= sprint_multiplier
		
	var target_vel: Vector3 = move_dir * current_speed
	velocity.x = move_toward(velocity.x, target_vel.x, 35.0 * delta)
	velocity.z = move_toward(velocity.z, target_vel.z, 35.0 * delta)
	
	# 6. Плавный поворот корпуса персонажа (лицо смотрит на -Z, джетпак на +Z)
	if visual_root:
		# Если игрок стреляет (зажата ЛКМ/ПКМ) или стоит на месте: персонаж смотрит строго туда же, куда и камера (спиной к нам, лицом к прицелу):
		if is_firing or not is_moving or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, camera_yaw, delta * 14.0)
		else:
			# Если игрок бежит без стрельбы: поворачивается лицом (-Z) точно по вектору move_dir:
			var target_angle: float = atan2(-move_dir.x, -move_dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, delta * 12.0)
		
	# 7. Процедурная анимация ходьбы, прыжка и стойки
	_update_procedural_animations(delta, is_moving, is_sprinting)
		
	# 8. Прыжки, гравитация и прижатие к полу
	if is_on_floor():
		air_jumps_used = 0
		if velocity.y < 0.0:
			velocity.y = -0.5
		if Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE):
			velocity.y = base_jump_velocity
	else:
		velocity.y -= gravity * delta
		if Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE):
			var max_extra: int = inventory.get_extra_jumps()
			if air_jumps_used < max_extra:
				air_jumps_used += 1
				velocity.y = base_jump_velocity * 0.95
				
	# 9. Активация рывка (Shift / C)
	if (Input.is_action_just_pressed("dash") or Input.is_key_pressed(KEY_C)) and not is_dashing and utility_cooldown <= 0.0:
		_execute_dash(move_dir)
		
	# 10. Взаимодействие (E)
	if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_E):
		_try_interact()
		
	# 11. Боевые действия (стрельба)
	_handle_combat_inputs()
	
	if is_inside_tree():
		move_and_slide()


func _update_procedural_animations(delta: float, is_moving: bool, is_sprinting: bool) -> void:
	if not visual_root:
		return
	ProceduralAnimator.animate_character_walk(
		delta,
		anim_time,
		is_moving and is_on_floor(),
		is_sprinting,
		is_on_floor(),
		visual_root,
		_commando_legs,
		_commando_arms,
		velocity.y
	)



func _check_interaction_ray() -> void:
	if not interact_raycast:
		return
		
	var collider: Object = interact_raycast.get_collider()
	current_interactable = null
	if collider is Node:
		var target: Node = collider as Node
		while target and not (target.has_method("interact") or target is Chest or target is Teleporter):
			target = target.get_parent()
		if target and (target.has_method("interact") or target is Chest or target is Teleporter):
			current_interactable = target as Node3D


func _try_interact() -> void:
	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.call("interact", self)


func _get_camera_move_dir() -> Vector3:
	# Читаем ввод явно, чтобы исключить путаницу знаков:
	var forward_input: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var right_input: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	# Fallback на случай, если используются стандартные ui_ действия или клавиши WASD напрямую:
	if is_zero_approx(forward_input) and is_zero_approx(right_input):
		if Input.is_key_pressed(KEY_W): forward_input += 1.0
		if Input.is_key_pressed(KEY_S): forward_input -= 1.0
		if Input.is_key_pressed(KEY_D): right_input += 1.0
		if Input.is_key_pressed(KEY_A): right_input -= 1.0

	# Вектор ВПЕРЁД (от камеры вглубь экрана) и ВПРАВО на горизонтальной плоскости XZ:
	var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
	var cam_forward: Vector3 = -cam_basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right: Vector3 = cam_basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	# При нажатии W (forward_input > 0) персонаж гарантированно идёт ВПЕРЁД (по cam_forward):
	var input_vec: Vector3 = cam_forward * forward_input + cam_right * right_input
	return input_vec.normalized() if input_vec.length_squared() > 0.001 else Vector3.ZERO


func _execute_dash(dir: Vector3) -> void:
	if is_dashing or utility_cooldown > 0.0:
		return
	is_dashing = true
	dash_timer = 0.32
	utility_cooldown = 3.5
	if dir.length_squared() > 0.01:
		dash_direction = dir.normalized()
	else:
		var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot else global_transform.basis
		var cam_forward: Vector3 = -cam_basis.z
		cam_forward.y = 0.0
		dash_direction = cam_forward.normalized()



func launch_upward(force: float = 24.0) -> void:
	velocity.y = force


func _handle_combat_inputs() -> void:
	is_firing = false
	# ЛКМ: Основной огонь (Double Tap)
	var fire_primary: bool = Input.is_action_pressed("primary_attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if fire_primary:
		is_firing = true
		if primary_cooldown <= 0.0:
			_shoot_primary()
		
	# ПКМ: Пробивающий выстрел (Phase Round)
	var fire_secondary: bool = Input.is_action_just_pressed("secondary_attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if fire_secondary and secondary_cooldown <= 0.0:
		is_firing = true
		_shoot_secondary()
		
	# Q: Осколочная граната
	var fire_special: bool = Input.is_action_just_pressed("special") or Input.is_key_pressed(KEY_Q)
	if fire_special and special_cooldown <= 0.0:
		is_firing = true
		_throw_grenade()


func _shoot_primary() -> void:
	var fire_rate: float = base_primary_rate / inventory.get_attack_speed_multiplier()
	primary_cooldown = fire_rate
	
	var spawn_node: Node3D = blaster_left if fire_left else blaster_right
	fire_left = !fire_left
	if not spawn_node:
		spawn_node = self
		
	# Процедурная отдача оружия
	ProceduralAnimator.apply_recoil(spawn_node, 0.12)
		
	var aim_point: Vector3 = _get_aim_world_point()
	var shoot_dir: Vector3 = (aim_point - spawn_node.global_position).normalized()
	
	var proj: Projectile = projectile_scene.instantiate() as Projectile
	if proj:
		get_parent().add_child(proj)
		proj.global_position = spawn_node.global_position
		proj.direction = shoot_dir
		proj.damage = base_damage * (1.0 + level * 0.15)
		proj.is_crit = inventory.check_crit()
		if proj.is_crit:
			proj.damage *= 2.0
		proj.player_inventory = inventory


func _shoot_secondary() -> void:
	secondary_cooldown = 2.8
	var aim_point: Vector3 = _get_aim_world_point()
	var spawn_pos: Vector3 = global_position + Vector3(0.0, 1.2, 0.0)
	var shoot_dir: Vector3 = (aim_point - spawn_pos).normalized()
	
	var proj: Projectile = projectile_scene.instantiate() as Projectile
	if proj:
		get_parent().add_child(proj)
		proj.global_position = spawn_pos
		proj.direction = shoot_dir
		proj.scale = Vector3(2.0, 2.0, 2.0)
		proj.damage = base_damage * 3.5 * (1.0 + level * 0.15)
		proj.is_crit = true
		proj.player_inventory = inventory


func _throw_grenade() -> void:
	special_cooldown = 4.5
	var aim_point: Vector3 = _get_aim_world_point()
	var spawn_pos: Vector3 = global_position + Vector3(0.0, 1.2, 0.0)
	var shoot_dir: Vector3 = (aim_point - spawn_pos).normalized()
	
	var proj: Projectile = projectile_scene.instantiate() as Projectile
	if proj:
		get_parent().add_child(proj)
		proj.global_position = spawn_pos
		proj.direction = shoot_dir
		proj.speed = 32.0
		proj.scale = Vector3(1.8, 1.8, 1.8)
		proj.damage = base_damage * 4.5
		proj.is_crit = true
		proj.player_inventory = inventory


func _get_aim_world_point() -> Vector3:
	if not camera:
		return global_position + -global_transform.basis.z * 20.0
		
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var cam_pos: Vector3 = camera.global_position
	var forward: Vector3 = -camera.global_transform.basis.z
	var ray_end: Vector3 = cam_pos + forward * 80.0
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_pos, ray_end)
	query.exclude = [self]
	query.collision_mask = 5 # World (1) + Enemies (4)
	var result: Dictionary = space_state.intersect_ray(query)
	
	if not result.is_empty():
		return result.position as Vector3
	return ray_end


func _update_cooldowns(delta: float) -> void:
	primary_cooldown = maxf(0.0, primary_cooldown - delta)
	secondary_cooldown = maxf(0.0, secondary_cooldown - delta)
	utility_cooldown = maxf(0.0, utility_cooldown - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	
	skill_cooldown_updated.emit("secondary", secondary_cooldown / 2.8)
	skill_cooldown_updated.emit("utility", utility_cooldown / 3.5)
	skill_cooldown_updated.emit("special", special_cooldown / 4.5)


func take_damage(amount: float) -> void:
	if inventory and inventory.check_block_damage():
		if damage_num_scene:
			var dmg_pop: DamageNumber = damage_num_scene.instantiate() as DamageNumber
			if dmg_pop:
				get_parent().add_child(dmg_pop)
				dmg_pop.popup(0.0, true, global_position + Vector3(0.0, 1.5, 0.0))
		return
		
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if damage_num_scene:
		var dmg_pop: DamageNumber = damage_num_scene.instantiate() as DamageNumber
		if dmg_pop:
			get_parent().add_child(dmg_pop)
			dmg_pop.popup(amount, false, global_position + Vector3(0.0, 1.2, 0.0))
	
	if current_health <= 0.0:
		current_health = max_health
		global_position = Vector3(0.0, 3.0, 0.0)
		health_changed.emit(current_health, max_health)


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func add_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(xp_needed * 1.5)
		max_health += 20.0
		current_health = max_health
		base_damage += 2.5
	xp_changed.emit(xp, xp_needed, level)
	health_changed.emit(current_health, max_health)


func _on_item_collected(item: ItemData, total: int) -> void:
	_recalculate_stats()
	_update_item_visuals(item)
	item_collected_banner.emit(item, total)


func _recalculate_stats() -> void:
	if inventory:
		max_health = inventory.get_max_health(110.0 + (level - 1) * 20.0)
		health_changed.emit(current_health, max_health)


var _item_aura_light: OmniLight3D


func _setup_item_aura() -> void:
	if not _item_aura_light:
		_item_aura_light = OmniLight3D.new()
		_item_aura_light.name = "ItemAuraLight"
		_item_aura_light.light_energy = 0.0
		_item_aura_light.omni_range = 3.5
		_item_aura_light.position = Vector3(0, 1.1, 0)
		add_child(_item_aura_light)


func _update_item_visuals(latest_item: ItemData = null) -> void:
	_setup_item_aura()
	if not is_instance_valid(_item_aura_light) or not inventory:
		return
		
	var total_items: int = 0
	var highest_tier: ItemData.ItemTier = ItemData.ItemTier.WHITE
	for item_id in inventory.items.keys():
		var cnt: int = inventory.items[item_id]
		total_items += cnt
		if inventory.item_registry.has(item_id):
			var it: ItemData = inventory.item_registry[item_id]
			if it.tier > highest_tier:
				highest_tier = it.tier
				
	var aura_color: Color = Color(0.5, 0.85, 1.0)
	match highest_tier:
		ItemData.ItemTier.WHITE:
			aura_color = Color(0.5, 0.85, 1.0)
		ItemData.ItemTier.GREEN:
			aura_color = Color(0.25, 1.0, 0.5)
		ItemData.ItemTier.RED:
			aura_color = Color(1.0, 0.3, 0.3)
		ItemData.ItemTier.BOSS:
			aura_color = Color(1.0, 0.85, 0.2)
			
	_item_aura_light.light_color = aura_color
	var target_energy: float = clampf(0.4 + total_items * 0.15, 0.4, 2.5)
	
	# Яркая вспышка ауры при подборе нового предмета
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(_item_aura_light, "light_energy", target_energy * 2.2, 0.15)
	flash_tween.tween_property(_item_aura_light, "light_energy", target_energy, 0.35)

