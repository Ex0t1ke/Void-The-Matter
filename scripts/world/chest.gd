class_name Chest
extends StaticBody3D
## Капсула снабжения / Сундук в стиле Risk of Rain.
## Открывается за Золото и выдает случайный предмет для стакания.

signal chest_opened(item: ItemData)

@export var cost: int = 25
@export var available_items: Array[ItemData] = []

var lid: Node3D
@onready var label: Label3D = $Label3D
@onready var light: OmniLight3D = $OmniLight3D
@onready var area: Area3D = $Area3D

var is_opened: bool = false
var player_in_range: PlayerController = null


func _ready() -> void:
	# Коллизия сундука: Layer 1 (World=1) + Layer 4 (Interactables=8) = 9
	collision_layer = 9
	collision_mask = 2 # Игрок
	
	if area:
		# Зона взаимодействия: Layer 4 (Interactables = 8)
		area.collision_layer = 8
		area.collision_mask = 2 # Игрок
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		
	if available_items.is_empty():
		_load_default_items()
	_setup_chest_model()
	_update_label()


func _setup_chest_model() -> void:
	if has_node("BaseMesh"):
		get_node("BaseMesh").queue_free()
	if has_node("LidMesh"):
		get_node("LidMesh").queue_free()
		
	var model: Node3D = ProceduralModelBuilder.build_chest()
	add_child(model)
	
	var model_lid: Node3D = model.find_child("Lid", true, false) as Node3D
	if model_lid:
		lid = model_lid



func interact(player: PlayerController) -> bool:
	if is_opened or not is_instance_valid(player):
		return false
	player_in_range = player
	return _try_open()


func _unhandled_input(event: InputEvent) -> void:
	if is_opened or not is_instance_valid(player_in_range):
		return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_try_open()


func _try_open() -> bool:
	if is_opened or not is_instance_valid(player_in_range):
		return false
		
	if player_in_range.gold >= cost:
		player_in_range.add_gold(-cost)
		is_opened = true
		_open_chest()
		return true
	else:
		_flash_insufficient_funds()
		return false


func _open_chest() -> void:
	if label:
		label.text = "ОТКРЫТО"
		label.modulate = Color(0.5, 0.5, 0.5, 0.6)
	
	# Выбираем случайный предмет и спавним его как 3D-объект
	var chosen_item: ItemData = null
	if not available_items.is_empty():
		chosen_item = available_items.pick_random() as ItemData
		
	if chosen_item:
		var drop_scene: PackedScene = preload("res://scenes/world/dropped_item.tscn")
		var dropped: DroppedItem = drop_scene.instantiate() as DroppedItem
		if dropped:
			dropped.item_data = chosen_item
			get_parent().add_child(dropped)
			dropped.global_position = global_position + Vector3(0.0, 0.8, 0.0)
		chest_opened.emit(chosen_item)
		
	# Анимация открытия крышки
	if lid:
		var tween: Tween = create_tween()
		tween.tween_property(lid, "rotation_degrees:x", -85.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if light:
		var ltween: Tween = create_tween()
		ltween.tween_property(light, "light_energy", 4.5, 0.2)
		ltween.tween_property(light, "light_energy", 1.2, 0.6)


func _flash_insufficient_funds() -> void:
	if not label:
		return
	var orig_color: Color = label.modulate
	label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween: Tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(label, "modulate", orig_color, 0.2)


func _on_body_entered(body: Node3D) -> void:
	var p: PlayerController = body as PlayerController
	if not p and body.get_parent() is PlayerController:
		p = body.get_parent() as PlayerController
	if p:
		player_in_range = p


func _on_body_exited(body: Node3D) -> void:
	var p: PlayerController = body as PlayerController
	if not p and body.get_parent() is PlayerController:
		p = body.get_parent() as PlayerController
	if p == player_in_range:
		player_in_range = null


func _update_label() -> void:
	if label:
		label.text = "[E] Открыть ($%d)" % cost


func _load_default_items() -> void:
	var paths: Array[String] = [
		"res://resources/items/soldiers_syringe.tres",
		"res://resources/items/gasoline.tres",
		"res://resources/items/ukulele.tres",
		"res://resources/items/hopoo_feather.tres",
		"res://resources/items/tougher_times.tres"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var item: ItemData = load(p) as ItemData
			if item:
				available_items.append(item)
