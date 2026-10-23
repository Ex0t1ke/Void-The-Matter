class_name ProceduralAnimator
extends Node
## Процедурный аниматор персонажей и врагов для Risk of Void.
## Обеспечивает покачивание при ходьбе, наклон корпуса, перебирание лап и вращение рун.


## Анимация бега, прыжка и наклона персонажа (Commando)
static func animate_character_walk(
	delta: float,
	time: float,
	is_moving: bool,
	is_sprinting: bool,
	is_on_ground: bool,
	visual_root: Node3D,
	legs: Array[Node3D],
	arms: Array[Node3D],
	velocity_y: float = 0.0
) -> void:
	if not visual_root:
		return
		
	if not is_on_ground:
		# Прыжок / Падение: ноги слегка поджаты (одна выше другой), руки разведены для баланса
		var air_pitch: float = clampf(-velocity_y * 0.012, deg_to_rad(-8.0), deg_to_rad(10.0))
		visual_root.rotation.x = lerp_angle(visual_root.rotation.x, air_pitch, 8.0 * delta)
		visual_root.position.y = lerpf(visual_root.position.y, 0.0, 10.0 * delta)
		
		if legs.size() >= 2:
			if is_instance_valid(legs[0]):
				legs[0].rotation.x = lerp_angle(legs[0].rotation.x, deg_to_rad(24.0), 10.0 * delta)
				legs[0].rotation.z = lerp_angle(legs[0].rotation.z, deg_to_rad(4.0), 10.0 * delta)
			if is_instance_valid(legs[1]):
				legs[1].rotation.x = lerp_angle(legs[1].rotation.x, deg_to_rad(10.0), 10.0 * delta)
				legs[1].rotation.z = lerp_angle(legs[1].rotation.z, deg_to_rad(-4.0), 10.0 * delta)
				
		if arms.size() >= 2:
			if is_instance_valid(arms[0]):
				arms[0].rotation.x = lerp_angle(arms[0].rotation.x, deg_to_rad(-12.0), 10.0 * delta)
				arms[0].rotation.z = lerp_angle(arms[0].rotation.z, deg_to_rad(16.0), 10.0 * delta)
			if is_instance_valid(arms[1]):
				arms[1].rotation.x = lerp_angle(arms[1].rotation.x, deg_to_rad(-12.0), 10.0 * delta)
				arms[1].rotation.z = lerp_angle(arms[1].rotation.z, deg_to_rad(-16.0), 10.0 * delta)
		return
		
	var speed_mult: float = 14.0 if is_sprinting else 10.0
	
	if is_moving:
		# Подошвы остаются на земле, легкий наклон корпуса вперед по ходу движения
		visual_root.position.y = lerpf(visual_root.position.y, 0.0, 12.0 * delta)
		var target_tilt: float = deg_to_rad(-8.0 if is_sprinting else -5.0)
		visual_root.rotation.x = lerp_angle(visual_root.rotation.x, target_tilt, 10.0 * delta)
		visual_root.rotation.z = lerp_angle(visual_root.rotation.z, 0.0, 10.0 * delta)
		
		# Махи руками и ногами в противофазе вокруг шарниров суставов
		var leg_swing: float = sin(time * speed_mult) * deg_to_rad(28.0)
		var arm_swing: float = -sin(time * speed_mult) * deg_to_rad(24.0)
		
		if legs.size() >= 2:
			if is_instance_valid(legs[0]):
				legs[0].rotation.x = leg_swing
				legs[0].rotation.z = lerp_angle(legs[0].rotation.z, 0.0, 10.0 * delta)
			if is_instance_valid(legs[1]):
				legs[1].rotation.x = -leg_swing
				legs[1].rotation.z = lerp_angle(legs[1].rotation.z, 0.0, 10.0 * delta)
			
		if arms.size() >= 2:
			if is_instance_valid(arms[0]):
				arms[0].rotation.x = arm_swing
				arms[0].rotation.z = lerp_angle(arms[0].rotation.z, 0.0, 10.0 * delta)
			if is_instance_valid(arms[1]):
				arms[1].rotation.x = -arm_swing
				arms[1].rotation.z = lerp_angle(arms[1].rotation.z, 0.0, 10.0 * delta)
	else:
		# Плавный возврат в спокойную стойку на земле (Idle)
		visual_root.position.y = lerpf(visual_root.position.y, 0.0, 12.0 * delta)
		visual_root.rotation.x = lerp_angle(visual_root.rotation.x, 0.0, 10.0 * delta)
		visual_root.rotation.z = lerp_angle(visual_root.rotation.z, 0.0, 10.0 * delta)
		
		for leg in legs:
			if is_instance_valid(leg):
				leg.rotation.x = lerp_angle(leg.rotation.x, 0.0, 10.0 * delta)
				leg.rotation.z = lerp_angle(leg.rotation.z, 0.0, 10.0 * delta)
		for arm in arms:
			if is_instance_valid(arm):
				arm.rotation.x = lerp_angle(arm.rotation.x, 0.0, 10.0 * delta)
				arm.rotation.z = lerp_angle(arm.rotation.z, 0.0, 10.0 * delta)


## Процедурная отдача оружия
static func apply_recoil(weapon: Node3D, kick_distance: float = 0.14) -> void:
	if not is_instance_valid(weapon):
		return
	var orig_z: float = weapon.position.z
	weapon.position.z += kick_distance
	var tween: Tween = weapon.create_tween()
	tween.tween_property(weapon, "position:z", orig_z, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Анимация лап жука (Beetle)
static func animate_beetle_legs(
	delta: float,
	time: float,
	is_moving: bool,
	legs: Array[Node3D]
) -> void:
	if not is_moving or legs.is_empty():
		return
	var cycle_speed: float = 12.0
	for i in range(legs.size()):
		var leg: Node3D = legs[i]
		if is_instance_valid(leg):
			var offset: float = (i % 2) * PI
			leg.rotation.z = sin(time * cycle_speed + offset) * deg_to_rad(18.0)


## Анимация парения и рунических колец Виспа (Wisp)
static func animate_wisp(
	_delta: float,
	time: float,
	root_mesh: Node3D,
	rings: Array[Node3D]
) -> void:
	if root_mesh:
		root_mesh.position.y = sin(time * 3.0) * 0.25
	if rings.size() >= 2:
		if is_instance_valid(rings[0]):
			rings[0].rotate_y(0.04)
		if is_instance_valid(rings[1]):
			rings[1].rotate_z(-0.03)


## Анимация парящих монолитов, поступных шагов и покачивания рук Каменного Титана
static func animate_titan(
	delta: float,
	time: float,
	is_moving: bool,
	shoulders: Array[Node3D],
	legs: Array[Node3D] = [],
	arms: Array[Node3D] = []
) -> void:
	# Парение монолитов-наплечников
	for i in range(shoulders.size()):
		var s: Node3D = shoulders[i]
		if is_instance_valid(s):
			s.position.y = 6.4 + sin(time * 2.0 + i * PI) * 0.25
			s.rotation.y = sin(time * 1.5 + i) * deg_to_rad(6.0)

	if is_moving:
		# Тяжёлая поступь колосса (низкая частота 3.2 rad/s, мощный размах)
		var leg_swing: float = sin(time * 3.2) * deg_to_rad(18.0)
		var arm_swing: float = -sin(time * 3.2) * deg_to_rad(15.0)
		if legs.size() >= 2:
			if is_instance_valid(legs[0]):
				legs[0].rotation.x = lerp_angle(legs[0].rotation.x, leg_swing, 8.0 * delta)
			if is_instance_valid(legs[1]):
				legs[1].rotation.x = lerp_angle(legs[1].rotation.x, -leg_swing, 8.0 * delta)
		if arms.size() >= 2:
			if is_instance_valid(arms[0]):
				arms[0].rotation.x = lerp_angle(arms[0].rotation.x, arm_swing, 8.0 * delta)
			if is_instance_valid(arms[1]):
				arms[1].rotation.x = lerp_angle(arms[1].rotation.x, -arm_swing, 8.0 * delta)
	else:
		# Плавный возврат в стойку покоя с медленным дыханием
		var idle_breathe: float = sin(time * 1.6) * deg_to_rad(3.0)
		for leg in legs:
			if is_instance_valid(leg):
				leg.rotation.x = lerp_angle(leg.rotation.x, 0.0, 6.0 * delta)
		for i in range(arms.size()):
			var arm: Node3D = arms[i]
			if is_instance_valid(arm):
				arm.rotation.x = lerp_angle(arm.rotation.x, idle_breathe * (1.0 if i % 2 == 0 else -1.0), 6.0 * delta)


## Анимация вращения кристалла и рунических колец Телепорта
static func animate_teleporter(
	_delta: float,
	time: float,
	crystal: Node3D,
	rune_ring: Node3D
) -> void:
	if is_instance_valid(crystal):
		crystal.position.y = 3.2 + sin(time * 2.2) * 0.35
		crystal.rotate_y(0.02)
	if is_instance_valid(rune_ring):
		rune_ring.rotate_y(-0.015)

