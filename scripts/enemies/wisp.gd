class_name WispEnemy
extends EnemyBase
## Враг "Малый Огонек" (Lesser Wisp) — летающий дальнобойный враг.
## Парит над полем боя, держит дистанцию и стреляет огненными зарядами с телеграфом зарядки.

var shoot_cooldown: float = 2.4
var time_passed: float = 0.0
var is_charging_shot: bool = false
var charge_timer: float = 0.0
const CHARGE_DURATION: float = 0.65

@onready var light: OmniLight3D = $OmniLight3D
var projectile_scene: PackedScene = preload("res://scenes/vfx/wisp_projectile.tscn")


var _wisp_model: Node3D
var _wisp_rings: Array[Node3D] = []


func _ready() -> void:
	super._ready()
	max_health = 45.0
	current_health = 45.0
	gold_reward = 10
	xp_reward = 15
	move_speed = 5.2
	
	_setup_wisp_model()


func _setup_wisp_model() -> void:
	if has_node("MeshInstance3D"):
		get_node("MeshInstance3D").queue_free()
		
	_wisp_model = ProceduralModelBuilder.build_wisp()
	add_child(_wisp_model)
	
	for child in _wisp_model.get_children():
		if child.name.begins_with("RuneRing"):
			_wisp_rings.append(child as Node3D)



func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_instance_valid(target_player):
		_find_player()
		return
		
	time_passed += delta
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	
	if is_charging_shot:
		charge_timer -= delta
		velocity = velocity.move_toward(Vector3.ZERO, 10.0 * delta)
		move_and_slide()
		look_at(target_player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		if charge_timer <= 0.0:
			_release_shot()
		return
		
	# Парение в воздухе и удержание дистанции (9..15м)
	var target_pos: Vector3 = target_player.global_position + Vector3(0.0, 4.0, 0.0)
	var dir: Vector3 = (target_pos - global_position)
	var dist: float = dir.length()
	
	if dist > 14.0:
		velocity = dir.normalized() * move_speed
	elif dist < 8.5:
		velocity = -dir.normalized() * move_speed
	else:
		velocity = velocity.move_toward(Vector3.ZERO, 6.0 * delta)
		
	velocity.y += sin(time_passed * 3.5) * 0.35
	move_and_slide()
	
	ProceduralAnimator.animate_wisp(delta, time_passed, _wisp_model, _wisp_rings)
	
	look_at(target_player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)

	
	# Подготовка к стрельбе
	if shoot_cooldown <= 0.0 and dist <= 24.0:
		_begin_charge_shot()


func _begin_charge_shot() -> void:
	is_charging_shot = true
	charge_timer = CHARGE_DURATION
	
	if light:
		var tween: Tween = create_tween()
		tween.tween_property(light, "light_energy", 6.0, CHARGE_DURATION)
		tween.tween_property(light, "light_energy", 2.5, 0.2)


func _release_shot() -> void:
	is_charging_shot = false
	shoot_cooldown = 2.6
	
	if not is_instance_valid(target_player):
		return
		
	if projectile_scene:
		var proj: Projectile = projectile_scene.instantiate() as Projectile
		if proj:
			get_parent().add_child(proj)
			proj.global_position = global_position
			var target_aim: Vector3 = target_player.global_position + Vector3(0.0, 0.9, 0.0)
			proj.direction = (target_aim - global_position).normalized()
			proj.speed = 26.0
			proj.damage = 12.0
			proj.is_enemy_projectile = true
			# Снаряд врага поражает игрока (Layer 2 = 2) и мир (Layer 1 = 1) -> Mask = 3
			proj.collision_mask = 3
