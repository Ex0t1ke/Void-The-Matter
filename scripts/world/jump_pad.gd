class_name JumpPad
extends Area3D
## Гравитационный гейзер (Jump Pad) в стиле Risk of Rain 2.
## Подбрасывает игрока высоко в воздух для динамичного перемещения по острову.

@export var launch_force: float = 26.0

@onready var light: OmniLight3D = $OmniLight3D
@onready var pad_mesh: MeshInstance3D = $PadMesh


func _ready() -> void:
	collision_layer = 8 # Layer 4 (Interactables)
	collision_mask = 2  # Layer 2 (Player)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player: PlayerController = body as PlayerController
	if not player and body.get_parent() is PlayerController:
		player = body.get_parent() as PlayerController
		
	if player:
		# Запуск игрока в воздух
		if player.has_method("launch_upward"):
			player.launch_upward(launch_force)
		elif "velocity" in player:
			player.velocity.y = launch_force
			
		_play_launch_fx()


func _play_launch_fx() -> void:
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "jump")

		
	# Световой импульс
	if light:
		var tween: Tween = create_tween()
		tween.tween_property(light, "light_energy", 5.0, 0.08)
		tween.tween_property(light, "light_energy", 1.8, 0.3)
		
	# Пульсация площадки
	if pad_mesh:
		var mtween: Tween = create_tween()
		mtween.tween_property(pad_mesh, "scale", Vector3(1.25, 0.6, 1.25), 0.08)
		mtween.tween_property(pad_mesh, "scale", Vector3.ONE, 0.22)
