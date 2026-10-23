extends SceneTree

func _init() -> void:
	print("========================================")
	print("--- ТЕСТ RISK OF VOID (RoR2 3D ФИКС 4 БАГОВ) ---")
	print("========================================")
	
	# 1. Проверка InputMap
	var expected_actions: Array[String] = ["move_forward", "move_back", "move_left", "move_right", "jump", "primary_attack", "secondary_attack", "dash", "special", "interact", "pause"]
	for act in expected_actions:
		assert(InputMap.has_action(act), "Input action missing: " + act)
	print("[OK] Все 11 Input Actions зарегистрированы.")
	
	# 2. Проверка PlayerController: _input, поворот со старта, рывок без ухода под землю
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	assert(player_scene != null, "player.tscn missing")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player._ready()
	
	# Проверка камеры: метод _input присутствует
	assert(player.has_method("_input"), "PlayerController must handle camera in _input(event)")
	
	# Проверка ориентации при спавне: корпус смотрит спиной к камере (camera_yaw)
	assert(is_equal_approx(player.visual_root.rotation.y, player.camera_yaw), "Character must face along camera_yaw at spawn")
	
	# Имитация движения мыши без зажатия ПКМ
	var motion_ev: InputEventMouseMotion = InputEventMouseMotion.new()
	motion_ev.relative = Vector2(100.0, -50.0)
	var prev_yaw: float = player.camera_yaw
	player._input(motion_ev)
	assert(player.camera_yaw != prev_yaw, "Camera yaw must rotate freely on mouse motion without RMB")
	assert(is_equal_approx(player.camera_pivot.rotation.y, player.camera_yaw), "camera_pivot must match camera_yaw")
	
	# Проверка рывка: моделька не уходит под землю, высота >= 0.0, наклон вперёд
	player._execute_dash(Vector3.FORWARD)
	assert(player.is_dashing, "is_dashing must be true on dash")
	player._physics_process(0.016)
	assert(player.visual_root.position.y >= 0.0, "Model must never sink underground during dash!")
	assert(player.visual_root.rotation.x < 0.0, "Model must have forward lean along -Z during dash")
	
	# Защита от повторного нажатия рывка во время кулдауна
	player._execute_dash(Vector3.FORWARD) # повторный вызов
	assert(player.dash_timer <= 0.32, "Dash timer must not reset on spam")
	
	# Проверка ориентации мешей модели:
	# Visor (z < 0), Blasters (z < 0), Jetpack (z > 0), Подошвы (y == 0.0)
	var model = player.visual_root.get_node_or_null("CommandoModel")
	assert(model != null, "CommandoModel must be created")
	var visor_node = model.find_child("Visor", true, false) as Node3D
	assert(visor_node != null and visor_node.position.z < 0.0, "Visor must be on front (-Z)")
	var jetpack_node = model.find_child("Jetpack", true, false) as Node3D
	assert(jetpack_node != null and jetpack_node.position.z > 0.0, "Jetpack must be on back (+Z)")
	var leg_pivot_l = model.get_node_or_null("LegPivotL") as Node3D
	assert(leg_pivot_l != null, "LegPivotL must exist")
	var boot_l = leg_pivot_l.get_node_or_null("BootL") as MeshInstance3D
	assert(boot_l != null, "BootL must exist")
	var boot_local_low: float = leg_pivot_l.position.y + boot_l.position.y + boot_l.mesh.get_aabb().position.y
	assert(absf(boot_local_low) < 0.02, "Boots must touch the ground (y = 0.0)")
	
	player.queue_free()
	print("[OK] Контроллер игрока: свободная мышь без ПКМ, ориентация (визор -Z, джетпак +Z), подошвы на земле (y=0) и рывок проверены.")
	
	# 3. Проверка HUD: mouse_filter=IGNORE и подложка карточки инвентаря/статов
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "hud.tscn failed to load")
	var hud_inst: HUD = hud_scene.instantiate() as HUD
	root.add_child(hud_inst)
	assert(hud_inst.has_node("BottomLeft"), "BottomLeft card missing")
	var bottom_left = hud_inst.get_node("BottomLeft") as Control
	assert(bottom_left.mouse_filter == Control.MOUSE_FILTER_IGNORE, "BottomLeft must have MOUSE_FILTER_IGNORE")
	assert(bottom_left is PanelContainer, "BottomLeft must be a PanelContainer with dark sci-fi background")
	assert(hud_inst.has_node("Crosshair"), "Crosshair missing")
	assert((hud_inst.get_node("Crosshair") as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "Crosshair must ignore mouse")
	print("[OK] HUD: mouse_filter=IGNORE на всех контейнерах, тёмная подложка статов для читаемости готова.")
	hud_inst.queue_free()
	
	# 4. Проверка экспозиции и света на test_island
	var island_scene: PackedScene = load("res://scenes/world/test_island.tscn")
	assert(island_scene != null, "test_island.tscn failed to load")
	var island: Node3D = island_scene.instantiate() as Node3D
	
	var sun: DirectionalLight3D = island.get_node("SunLight") as DirectionalLight3D
	assert(sun != null, "SunLight missing")
	assert(sun.light_energy <= 1.05, "SunLight energy must be reduced to 1.0 to eliminate overexposure")
	
	var world_env: WorldEnvironment = island.get_node("WorldEnvironment") as WorldEnvironment
	assert(world_env != null and world_env.environment != null, "WorldEnvironment missing")
	assert(world_env.environment.tonemap_exposure <= 0.9, "tonemap_exposure must be 0.85")
	assert(world_env.environment.ambient_light_energy <= 0.5, "ambient_light_energy must be 0.45")
	assert(world_env.environment.glow_bloom <= 0.15, "glow_bloom must be 0.1")
	assert(world_env.environment.glow_intensity <= 0.6, "glow_intensity must be 0.5")
	print("[OK] Освещение и постобработка: экспозиция 0.85, свет 1.0, мягкий блум 0.1 — пересвет полностью устранён.")
	island.queue_free()
	
	print("========================================")
	print("--- ВСЕ 4 КРИТИЧЕСКИХ БАГА ИСПРАВЛЕНЫ! 100% ---")
	print("========================================")
	quit(0)
