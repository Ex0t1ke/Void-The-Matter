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

@export var charge_radius: float = 24.0
@export var charge_duration: float = 50.0 ## Время полной зарядки (сек)

var state: TeleporterState = TeleporterState.IDLE
var charge_progress: float = 0.0
var boss_is_defeated: bool = false
var player_inside_zone: bool = false

@onready var label: Label3D = $Label3D
@onready var zone_mesh: MeshInstance3D = $ZoneMesh
@onready var zone_light: OmniLight3D = $ZoneLight
@onready var area: Area3D = $ChargeArea

var titan_boss_scene: PackedScene = preload("res://scenes/enemies/stone_titan.tscn")
var active_boss: StoneTitanBoss = null


var _crystal: Node3D
var _rune_ring: Node3D
var _time_passed: float = 0.0


func _ready() -> void:
	if zone_mesh:
		zone_mesh.visible = false
	if area:
		# Layer 4 (Interactables = 8)
		area.collision_layer = 8
		area.collision_mask = 2 # Player
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		
	_setup_teleporter_model()
	_update_label()


func _setup_teleporter_model() -> void:
	if has_node("ProngLeft"):
		get_node("ProngLeft").queue_free()
	if has_node("ProngRight"):
		get_node("ProngRight").queue_free()
		
	var model: Node3D = ProceduralModelBuilder.build_teleporter()
	add_child(model)
	
	_crystal = model.find_child("FloatingCrystal", true, false) as Node3D
	_rune_ring = model.find_child("RuneRing", true, false) as Node3D



func interact(_player: PlayerController) -> void:
	if state == TeleporterState.IDLE:
		_start_event()
	elif state == TeleporterState.CHARGED:
		_finish_stage()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if player_inside_zone:
			if state == TeleporterState.IDLE:
				_start_event()
			elif state == TeleporterState.CHARGED:
				_finish_stage()


func _process(delta: float) -> void:
	_time_passed += delta
	ProceduralAnimator.animate_teleporter(delta, _time_passed, _crystal, _rune_ring)
	
	if state == TeleporterState.CHARGING:

		# Зарядка идет только пока игрок внутри зоны
		if player_inside_zone:
			charge_progress = minf(100.0, charge_progress + (100.0 / charge_duration) * delta)
			charge_updated.emit(charge_progress)
			if label:
				label.text = "ЗАРЯДКА: %d%%\n(Оставайтесь в зоне!)" % int(charge_progress)
		else:
			if label:
				label.text = "ЗАРЯДКА: %d%%\n[ ВЕРНИТЕСЬ В ЗОНУ! ]" % int(charge_progress)
			
		# Проверка завершения зарядки и гибели босса
		if charge_progress >= 100.0 and boss_is_defeated:
			state = TeleporterState.CHARGED
			teleporter_charged.emit()
			if label:
				label.text = "[E] Активировать Телепорт\n(ПЕРЕХОД НА СЛЕДУЮЩИЙ ЭТАП)"
				label.modulate = Color(0.2, 1.0, 0.4, 1.0)
			if zone_light:
				zone_light.light_color = Color(0.2, 1.0, 0.4, 1.0)


func _start_event() -> void:
	if state != TeleporterState.IDLE:
		return
	state = TeleporterState.CHARGING
	charge_progress = 0.0
	teleporter_activated.emit()
	
	if zone_mesh:
		zone_mesh.visible = true
	if zone_light:
		zone_light.light_energy = 3.5
		
	# Призываем Босса (Каменный Титан)
	var spawn_pos: Vector3 = global_position + Vector3(randf_range(-15.0, 15.0), 0.0, randf_range(12.0, 18.0))
	if titan_boss_scene:
		active_boss = titan_boss_scene.instantiate() as StoneTitanBoss
		if active_boss:
			get_parent().add_child(active_boss)
			active_boss.global_position = spawn_pos
			boss_spawned.emit(active_boss)
			
			active_boss.titan_slain.connect(func() -> void:
				boss_is_defeated = true
				if charge_progress >= 100.0:
					state = TeleporterState.CHARGED
					if label:
						label.text = "[E] Активировать Телепорт\n(ПЕРЕХОД НА СЛЕДУЮЩИЙ ЭТАП)"
						label.modulate = Color(0.2, 1.0, 0.4, 1.0)
			)


func _finish_stage() -> void:
	state = TeleporterState.COMPLETED
	stage_completed.emit()
	if label:
		label.text = "ЭТАП ЗАВЕРШЕН!"
	if zone_light:
		var tween: Tween = create_tween()
		tween.tween_property(zone_light, "light_energy", 12.0, 0.4)
		tween.tween_interval(1.5)
		tween.tween_callback(func() -> void:
			get_tree().reload_current_scene()
		)


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController or (body.get_parent() and body.get_parent() is PlayerController):
		player_inside_zone = true


func _on_body_exited(body: Node3D) -> void:
	if body is PlayerController or (body.get_parent() and body.get_parent() is PlayerController):
		player_inside_zone = false


func _update_label() -> void:
	if label:
		label.text = "[E] Активировать Телепорт\n(Призывает Босса)"
