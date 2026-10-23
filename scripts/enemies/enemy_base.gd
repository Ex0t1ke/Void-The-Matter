class_name EnemyBase
extends CharacterBody3D
## Базовый класс врагов в стиле Risk of Rain.
## Поддерживает масштабирование сложности, расчет урона, критов и наград.

signal died(enemy: EnemyBase)
signal health_updated(current: float, max_hp: float)

@export var max_health: float = 60.0
@export var move_speed: float = 5.0
@export var damage: float = 8.0
@export var gold_reward: int = 6
@export var xp_reward: int = 10

var current_health: float = 60.0
var target_player: PlayerController = null
var is_dead: bool = false

var damage_num_scene: PackedScene = preload("res://scenes/world/damage_number.tscn")


func _ready() -> void:
	add_to_group("enemies")
	# Collision Layer 3 (бит 3 -> значение 4)
	collision_layer = 4
	# Collision Mask: Layer 1 (World=1) + Layer 2 (Player=2) = 3
	collision_mask = 3
	current_health = max_health
	_find_player()


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is PlayerController:
		target_player = players[0] as PlayerController


func take_damage(amount: float, is_crit: bool = false) -> void:
	if is_dead:
		return
		
	current_health = maxf(0.0, current_health - amount)
	health_updated.emit(current_health, max_health)
	
	# Создаем всплывающее число урона
	if damage_num_scene:
		var dmg_pop: DamageNumber = damage_num_scene.instantiate() as DamageNumber
		if dmg_pop:
			var parent_node: Node = get_parent()
			if parent_node:
				parent_node.add_child(dmg_pop)
				dmg_pop.popup(amount, is_crit, global_position + Vector3(0.0, 1.2, 0.0))
	
	# Мигание при получении урона
	_flash_hit()
	
	if current_health <= 0.0:
		die()


func _flash_hit() -> void:
	var meshes: Array[MeshInstance3D] = []
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			meshes.append(child as MeshInstance3D)
			
	if meshes.is_empty():
		return
		
	var orig_materials: Dictionary = {}
	var flash_mat: StandardMaterial3D = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 1.0, 1.0, 1.0)
	flash_mat.emission_energy_multiplier = 2.0
	
	for m in meshes:
		orig_materials[m] = m.get_surface_override_material(0)
		m.set_surface_override_material(0, flash_mat)
		
	var timer: SceneTreeTimer = get_tree().create_timer(0.08)
	timer.timeout.connect(func() -> void:
		for m in meshes:
			if is_instance_valid(m):
				m.set_surface_override_material(0, orig_materials.get(m, null))
	)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(self)
	
	if is_instance_valid(target_player):
		target_player.add_gold(gold_reward)
		target_player.add_xp(xp_reward)
		
		# Триггер прока убийства (Бензин)
		if target_player.inventory:
			var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
			target_player.inventory.trigger_on_kill(global_position, target_player.base_damage, enemies)
			
	_play_death_animation()


func _play_death_animation() -> void:
	# Отключаем коллизию перед удалением
	set_physics_process(false)
	var col: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.disabled = true
		
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 0.2, 1.3), 0.15)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(queue_free)
