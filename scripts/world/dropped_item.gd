class_name DroppedItem
extends CharacterBody3D
## Физический 3D-предмет, вылетающий из сундука или босса с подсветкой и частицами.

@export var item_data: ItemData
@export var float_speed: float = 2.5

@onready var mesh_root: Node3D = $MeshRoot
@onready var light: OmniLight3D = $OmniLight3D
@onready var pickup_area: Area3D = $PickupArea

var can_pickup: bool = false
var time_alive: float = 0.0
var target_player: PlayerController = null


func _ready() -> void:
	# Layer 4 (Interactables = 8)
	collision_layer = 8
	collision_mask = 1 # Ground
	
	if pickup_area:
		pickup_area.collision_layer = 8
		pickup_area.collision_mask = 2 # Player
		pickup_area.body_entered.connect(_on_pickup_entered)
		
	# Начальный импульс вверх и вбок
	var angle: float = randf() * TAU
	velocity = Vector3(cos(angle) * randf_range(1.5, 3.0), 6.5, sin(angle) * randf_range(1.5, 3.0))
	
	_setup_visuals()
	
	var timer: SceneTreeTimer = get_tree().create_timer(0.4)
	timer.timeout.connect(func() -> void: can_pickup = true)


func _setup_visuals() -> void:
	if not item_data:
		return
		
	var tier_color: Color = Color(0.85, 0.95, 1.0)
	match item_data.tier:
		ItemData.ItemTier.WHITE:
			tier_color = Color(0.3, 0.85, 1.0)
		ItemData.ItemTier.GREEN:
			tier_color = Color(0.2, 0.95, 0.4)
		ItemData.ItemTier.RED:
			tier_color = Color(1.0, 0.25, 0.2)
			
	if light:
		light.light_color = tier_color
		light.light_energy = 3.5


func _physics_process(delta: float) -> void:
	time_alive += delta
	
	# Гравитация и перемещение до приземления
	if not is_on_floor():
		velocity.y -= 20.0 * delta
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
		
	# Вращение и левитация
	if mesh_root:
		mesh_root.rotate_y(2.5 * delta)
		mesh_root.position.y = 0.4 + sin(time_alive * float_speed) * 0.12
		
	# Примагничивание к игроку, если он близко
	if can_pickup and is_instance_valid(target_player):
		var p_pos: Vector3 = target_player.global_position + Vector3(0.0, 0.8, 0.0)
		global_position = global_position.move_toward(p_pos, 18.0 * delta)
		if global_position.distance_to(p_pos) < 1.0:
			_collect(target_player)


func _on_pickup_entered(body: Node3D) -> void:
	if not can_pickup:
		return
	var player: PlayerController = body as PlayerController
	if not player and body.get_parent() is PlayerController:
		player = body.get_parent() as PlayerController
	if player:
		target_player = player
		_collect(player)


func _collect(player: PlayerController) -> void:
	can_pickup = false
	if is_instance_valid(player) and player.inventory and item_data:
		var audio: Node = get_node_or_null("/root/AudioManager")
		if audio and audio.has_method("play_sfx"):
			audio.call("play_sfx", "pickup")

		
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(queue_free)
