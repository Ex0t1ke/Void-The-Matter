class_name Teleporter
extends Node3D
## Древний Телепорт (The Teleporter) — ключевая цель забега в стиле Risk of Rain.
## Активация призывает Босса и запускает 50-секундное выживание в зоне зарядки.

signal teleporter_activated()
signal charge_updated(percent: float)
signal boss_spawned(boss: StoneTitanBoss)
signal teleporter_charged()
signal stage_completed()

enum TeleporterState {
	IDLE,       ## Ожидает активации игроком
	CHARGING,   ## Идет зарядка (0-100%), босс жив
	CHARGED,    ## 100% заряда, босс повержен -> готов к переходу
	COMPLETED   ## Переход на следующий этап
}

const COLOR_IDLE_AMBER: Color = Color(1.0, 0.55, 0.15, 0.65)
const COLOR_CHARGING_CYAN: Color = Color(0.0, 0.94, 1.0, 0.85)
const COLOR_CHARGED_GREEN: Color = Color(0.2, 1.0, 0.4, 0.9)

@export var charge_radius: float = 24.0
@export var charge_duration: float = 50.0 ## Время полной зарядки (сек)

var state: TeleporterState = TeleporterState.IDLE
var charge_progress: float = 0.0
var boss_is_defeated: bool = false
var player_inside_zone: bool = false
var player_in_interact_range: bool = false

@onready var label: Label3D = get_node_or_null("Label3D")
@onready var beacon_pillar: MeshInstance3D = get_node_or_null("BeaconPillar")
@onready var zone_dome: MeshInstance3D = get_node_or_null("ZoneDome")
@onready var zone_ring: MeshInstance3D = get_node_or_null("ZoneRing")
@onready var zone_light: OmniLight3D = get_node_or_null("ZoneLight")
@onready var interact_area: Area3D = get_node_or_null("InteractArea")
@onready var charge_area: Area3D = get_node_or_null("ChargeArea")

var titan_boss_scene: PackedScene = preload("res://scenes/enemies/stone_titan.tscn")
var active_boss: StoneTitanBoss = null

var _crystal: Node3D
var _rune_ring: Node3D
var _time_passed: float = 0.0


func _ready() -> void:
	if zone_dome:
		zone_dome.visible = false
	if zone_ring:
		zone_ring.visible = false
	if zone_light:
		zone_light.light_color = Color(1.0, 0.55, 0.15)
		zone_light.light_energy = 2.5

	_setup_teleporter_model()
	_setup_areas()
	_update_beacon_color(COLOR_IDLE_AMBER)
	_update_label()


func _setup_areas() -> void:
	if interact_area:
		interact_area.collision_layer = 8 # Layer 4 (Interactables)
		interact_area.collision_mask = 2  # Player
		if not interact_area.body_entered.is_connected(_on_interact_entered):
			interact_area.body_entered.connect(_on_interact_entered)
		if not interact_area.body_exited.is_connected(_on_interact_exited):
			interact_area.body_exited.connect(_on_interact_exited)

	if charge_area:
		charge_area.collision_layer = 8 # Layer 4 (Interactables)
		charge_area.collision_mask = 2  # Player
		if not charge_area.body_entered.is_connected(_on_charge_entered):
			charge_area.body_entered.connect(_on_charge_entered)
		if not charge_area.body_exited.is_connected(_on_charge_exited):
			charge_area.body_exited.connect(_on_charge_exited)


func _setup_teleporter_model() -> void:
	if has_node("ProngLeft"):
		get_node("ProngLeft").queue_free()
	if has_node("ProngRight"):
		get_node("ProngRight").queue_free()
		
	var model: Node3D = ProceduralModelBuilder.build_teleporter()
	add_child(model)
	
	# Удаляем встроенный SkyBeacon из ProceduralModelBuilder, так как на сцене уже есть BeaconPillar (160м)
	var sb: Node = model.find_child("SkyBeacon", true, false)
	if sb:
		sb.queue_free()

	_crystal = model.find_child("FloatingCrystal", true, false) as Node3D
	_rune_ring = model.find_child("RuneRing", true, false) as Node3D


func _update_beacon_color(color: Color) -> void:
	if not beacon_pillar:
		return
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beacon_pillar.set_surface_override_material(0, mat)


func interact(_player: PlayerController = null) -> void:
	if state == TeleporterState.IDLE:
		_start_event()
	elif state == TeleporterState.CHARGED:
		_finish_stage()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if player_in_interact_range or player_inside_zone:
			if state == TeleporterState.IDLE:
				_start_event()
			elif state == TeleporterState.CHARGED:
				_finish_stage()


func _process(delta: float) -> void:
	_time_passed += delta
	ProceduralAnimator.animate_teleporter(delta, _time_passed, _crystal, _rune_ring)
	
	if zone_ring and zone_ring.visible:
		zone_ring.rotate_y(delta * 0.2)

	if state == TeleporterState.CHARGING:
		# Зарядка идет только пока игрок внутри зоны (24м)
		if player_inside_zone:
			charge_progress = minf(100.0, charge_progress + (100.0 / charge_duration) * delta)
			charge_updated.emit(charge_progress)
			if label:
				label.text = "ЗАРЯДКА: %d%%\n(Оставайтесь в зоне!)" % int(charge_progress)
				label.modulate = Color(0.2, 0.95, 1.0)
		else:
			if label:
				label.text = "ЗАРЯДКА: %d%%\n[ ВЕРНИТЕСЬ В ЗОНУ! ]" % int(charge_progress)
				label.modulate = Color(1.0, 0.35, 0.35)
			
		# Проверка завершения зарядки и гибели босса
		if charge_progress >= 100.0 and boss_is_defeated:
			_set_state_charged()


func _start_event() -> void:
	if state != TeleporterState.IDLE:
		return
	state = TeleporterState.CHARGING
	charge_progress = 0.0
	teleporter_activated.emit()
	
	if zone_dome:
		zone_dome.visible = true
	if zone_ring:
		zone_ring.visible = true
	if zone_light:
		zone_light.light_color = Color(0.0, 0.94, 1.0)
		zone_light.light_energy = 4.0

	_update_beacon_color(COLOR_CHARGING_CYAN)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("teleporter_activate.wav", global_position)
		
	# Призываем Босса (Каменный Титан)
	var spawn_pos: Vector3 = global_position + Vector3(randf_range(-18.0, 18.0), 0.0, randf_range(14.0, 22.0))
	if titan_boss_scene:
		active_boss = titan_boss_scene.instantiate() as StoneTitanBoss
		if active_boss:
			get_parent().add_child(active_boss)
			active_boss.global_position = spawn_pos
			boss_spawned.emit(active_boss)
			
			active_boss.titan_slain.connect(func() -> void:
				boss_is_defeated = true
				if charge_progress >= 100.0:
					_set_state_charged()
			)


func _set_state_charged() -> void:
	if state == TeleporterState.CHARGED:
		return
	state = TeleporterState.CHARGED
	teleporter_charged.emit()
	_update_beacon_color(COLOR_CHARGED_GREEN)

	if zone_ring:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 1.0, 0.4, 0.85)
		zone_ring.set_surface_override_material(0, mat)

	if zone_light:
		zone_light.light_color = Color(0.2, 1.0, 0.4)
		zone_light.light_energy = 5.0

	if label:
		label.text = "[E] Активировать Телепорт\n(ПЕРЕХОД НА СЛЕДУЮЩИЙ ЭТАП)"
		label.modulate = Color(0.2, 1.0, 0.4)


func _finish_stage() -> void:
	state = TeleporterState.COMPLETED
	stage_completed.emit()
	if label:
		label.text = "ЭТАП ЗАВЕРШЕН!"
		label.modulate = Color(0.2, 1.0, 0.5)
	if zone_light:
		var tween: Tween = create_tween()
		tween.tween_property(zone_light, "light_energy", 14.0, 0.5)
		tween.tween_interval(1.5)
		tween.tween_callback(func() -> void:
			get_tree().reload_current_scene()
		)


func _is_player(body: Node3D) -> bool:
	return body is PlayerController or (body.get_parent() and body.get_parent() is PlayerController) or body.name == "Player"


func _on_interact_entered(body: Node3D) -> void:
	if _is_player(body):
		player_in_interact_range = true
		_update_label()


func _on_interact_exited(body: Node3D) -> void:
	if _is_player(body):
		player_in_interact_range = false
		_update_label()


func _on_charge_entered(body: Node3D) -> void:
	if _is_player(body):
		player_inside_zone = true


func _on_charge_exited(body: Node3D) -> void:
	if _is_player(body):
		player_inside_zone = false


func _update_label() -> void:
	if not label:
		return
	if state == TeleporterState.IDLE:
		if player_in_interact_range:
			label.text = "[E] Активировать Телепорт\n(Призывает Босса)"
			label.modulate = Color(1.0, 0.75, 0.2)
		else:
			label.text = "ДРЕВНИЙ ТЕЛЕПОРТ\n[Подойдите ближе для активации]"
			label.modulate = Color(0.85, 0.7, 0.3, 0.85)
	elif state == TeleporterState.CHARGED:
		label.text = "[E] Активировать Телепорт\n(ПЕРЕХОД НА СЛЕДУЮЩИЙ ЭТАП)"
		label.modulate = Color(0.2, 1.0, 0.4)
