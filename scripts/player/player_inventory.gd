class_name PlayerInventory
extends Node
## Менеджер инвентаря и бесконечного стекинга предметов в стиле Risk of Rain.
## Обрабатывает пассивные множители, шансы прока и on-kill/on-hit эффекты.

signal item_collected(item: ItemData, new_total: int)
signal proc_chain_lightning(origin: Vector3, targets: Array[Node3D])
signal proc_gasoline_explosion(position: Vector3, radius: float, damage: float)
signal damage_blocked()

## Словарь: item_id (StringName) -> count (int)
var item_counts: Dictionary = {}
## Словарь: item_id (StringName) -> ItemData
var item_registry: Dictionary = {}


func add_item(item: ItemData) -> void:
	if not item:
		return
	var item_id = item.id
	item_registry[item_id] = item
	item_counts[item_id] = item_counts.get(item_id, 0) + 1
	item_collected.emit(item, item_counts[item_id])


func get_count(item_id: StringName) -> int:
	return item_counts.get(item_id, 0)


## Расчет множителя скорости атаки (Шприцы Солдата)
func get_attack_speed_multiplier() -> float:
	var mult = 1.0
	for item_id in item_counts.keys():
		var data: ItemData = item_registry[item_id]
		mult += data.attack_speed_per_stack * item_counts[item_id]
	return mult


## Расчет скорости перемещения
func get_move_speed(base_speed: float) -> float:
	var mult = 1.0
	for item_id in item_counts.keys():
		var data: ItemData = item_registry[item_id]
		mult += data.move_speed_per_stack * item_counts[item_id]
	return base_speed * mult


## Расчет количества дополнительных прыжков (Перо Хопу)
func get_extra_jumps() -> int:
	var jumps = 0
	for item_id in item_counts.keys():
		var data: ItemData = item_registry[item_id]
		jumps += data.extra_jumps_per_stack * item_counts[item_id]
	return jumps


## Расчет максимального здоровья (Стейк Бизона)
func get_max_health(base_hp: float) -> float:
	var bonus = 0.0
	for item_id in item_counts.keys():
		var data: ItemData = item_registry[item_id]
		bonus += data.health_per_stack * item_counts[item_id]
	return base_hp + bonus


## Проверка шанса блокирования входящего урона (Плюшевый Мишка)
func check_block_damage() -> bool:
	var bear_count = get_count(&"tougher_times")
	if bear_count <= 0:
		return false
	# Гиперболическая формула RoR: 1 - 1 / (1 + 0.15 * count)
	var block_chance = 1.0 - (1.0 / (1.0 + 0.15 * bear_count))
	if randf() < block_chance:
		damage_blocked.emit()
		return true
	return false


## Проверка критического удара (Очки Линз)
func check_crit() -> bool:
	var crit_chance = 0.01 # Базовый 1%
	for item_id in item_counts.keys():
		var data: ItemData = item_registry[item_id]
		crit_chance += data.crit_chance_per_stack * item_counts[item_id]
	return randf() < clampf(crit_chance, 0.0, 1.0)


## Триггер при попадании во врага (Цепная молния Укулеле)
func trigger_on_hit(target: Node3D, damage: float, current_pos: Vector3, enemies_in_scene: Array) -> void:
	var ukulele_count = get_count(&"ukulele")
	if ukulele_count > 0:
		if randf() < 0.25:
			var max_targets = 3 + (ukulele_count - 1) * 2
			var targets: Array[Node3D] = []
			for enemy in enemies_in_scene:
				if enemy != target and is_instance_valid(enemy) and enemy is Node3D:
					if enemy.global_position.distance_to(current_pos) < 18.0:
						targets.append(enemy)
						if targets.size() >= max_targets:
							break
			if targets.size() > 0:
				proc_chain_lightning.emit(current_pos, targets)
				for t in targets:
					if t.has_method("take_damage"):
						t.take_damage(damage * 0.8, false)


## Триггер при убийстве врага (Взрыв Бензина)
func trigger_on_kill(kill_pos: Vector3, player_base_damage: float, enemies_in_scene: Array) -> void:
	var gas_count = get_count(&"gasoline")
	if gas_count > 0:
		var radius = 10.0 + (gas_count - 1) * 4.0
		var damage = player_base_damage * (1.5 + (gas_count - 1) * 0.5)
		proc_gasoline_explosion.emit(kill_pos, radius, damage)
		for enemy in enemies_in_scene:
			if is_instance_valid(enemy) and enemy is Node3D:
				if enemy.global_position.distance_to(kill_pos) <= radius:
					if enemy.has_method("take_damage"):
						enemy.take_damage(damage, false)
