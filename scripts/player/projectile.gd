class_name Projectile
extends Area3D
## Универсальный снаряд (Бластер Выжившего / Огонь Виспа / Лазер Титана).

@export var speed: float = 60.0
@export var max_lifetime: float = 3.0
@export var is_enemy_projectile: bool = false

var damage: float = 12.0
var is_crit: bool = false
var player_inventory: PlayerInventory = null
var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	# Layer 5 (Projectiles = 16)
	collision_layer = 16
	if is_enemy_projectile:
		# Поражает Мир (1) и Игрока (2) -> Mask = 3
		collision_mask = 3
	else:
		# Поражает Мир (1) и Врагов (4) -> Mask = 5
		collision_mask = 5
		
	body_entered.connect(_on_hit_body)
	area_entered.connect(_on_hit_area)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()


func _on_hit_body(body: Node3D) -> void:
	_process_hit(body)


func _on_hit_area(area: Area3D) -> void:
	_process_hit(area.get_parent() as Node3D)


func _process_hit(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
		
	if is_enemy_projectile:
		# Снаряд врага наносит урон только игроку
		if target is PlayerController or (target.get_parent() and target.get_parent() is PlayerController):
			var player: PlayerController = target if target is PlayerController else target.get_parent() as PlayerController
			if player and player.has_method("take_damage"):
				player.take_damage(damage)
			queue_free()
		elif target is StaticBody3D:
			queue_free()
	else:
		# Снаряд игрока наносит урон врагам
		if target is PlayerController:
			return
			
		if target.has_method("take_damage"):
			target.take_damage(damage, is_crit)
			
			# Триггер прока Укулеле (цепная молния)
			if player_inventory:
				var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
				player_inventory.trigger_on_hit(target, damage, global_position, enemies)
				
			queue_free()
		elif target is StaticBody3D:
			queue_free()
