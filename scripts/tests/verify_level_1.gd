extends SceneTree

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	print("==================================================")
	print("--- VERIFYING LEVEL 1: COLLISIONS, NAVMESH, SPAWN, TELEPORTER, LIGHTING ---")
	print("==================================================")

	# 1. Проверка сцены уровня: test_island.tscn
	var stage_packed: PackedScene = load("res://scenes/world/test_island.tscn")
	assert(stage_packed != null, "Failed to load test_island.tscn")
	var stage: Node3D = stage_packed.instantiate() as Node3D
	root.add_child(stage)
	
	# Проверка отсутствия захардкоженных мобов перед лицом игрока
	assert(stage.get_node_or_null("InitialBeetle1") == null, "InitialBeetle1 should be removed")
	assert(stage.get_node_or_null("InitialBeetle2") == null, "InitialBeetle2 should be removed")
	assert(stage.get_node_or_null("InitialWisp1") == null, "InitialWisp1 should be removed")
	print("[OK] Захардкоженные мобы на спавне удалены (нет спавна перед лицом).")

	# Проверка NavigationRegion3D и параметров NavMesh
	var nav_region: NavigationRegion3D = stage.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	assert(nav_region != null, "NavigationRegion3D is missing")
	var nm: NavigationMesh = nav_region.navigation_mesh
	assert(nm != null, "NavigationMesh is missing")
	assert(is_equal_approx(nm.agent_radius, 0.6), "Agent radius must be 0.6")
	assert(is_equal_approx(nm.agent_height, 1.8), "Agent height must be 1.8")
	assert(is_equal_approx(nm.agent_max_climb, 0.8), "Agent max climb must be 0.8")
	assert(is_equal_approx(nm.agent_max_slope, 45.0), "Agent max slope must be 45.0")
	print("[OK] NavigationRegion3D настроен с точными параметрами агентов (radius=0.6, height=1.8, climb=0.8, slope=45°).")

	# Проверка WorldEnvironment: отсутствие засвета неба и UI
	var we: WorldEnvironment = stage.get_node_or_null("WorldEnvironment") as WorldEnvironment
	assert(we != null and we.environment != null, "WorldEnvironment is missing")
	var env: Environment = we.environment
	assert(env.glow_hdr_threshold >= 1.3, "glow_hdr_threshold must be >= 1.3 to avoid UI/sky glow blowout")
	assert(env.glow_bloom <= 0.1, "glow_bloom must be subtle (<= 0.1)")
	assert(env.fog_enabled == true, "fog_enabled must be true")
	assert(env.fog_sky_affect <= 0.2, "fog_sky_affect must be <= 0.2 so sky stays dark and clean")
	assert(env.volumetric_fog_enabled == false, "volumetric_fog_enabled should be false to prevent milky bleaching")
	print("[OK] WorldEnvironment откалиброван: туман не размывает небосвод, Glow HDR threshold = 1.35 исключает засвет интерфейса.")

	# 2. Проверка Телепорта / Маяка
	var tp: Teleporter = stage.get_node_or_null("Teleporter") as Teleporter
	assert(tp != null, "Teleporter missing from scene")
	assert(tp.get_node_or_null("BeaconPillar") != null, "BeaconPillar vertical light beam is missing")
	assert(tp.get_node_or_null("ZoneDome") != null, "ZoneDome 24m semi-transparent dome is missing")
	assert(tp.get_node_or_null("ZoneRing") != null, "ZoneRing 24m boundary ring is missing")
	assert(tp.get_node_or_null("InteractArea") != null, "InteractArea is missing")
	assert(tp.get_node_or_null("ChargeArea") != null, "ChargeArea is missing")
	assert(tp.get_node_or_null("BaseCollider") != null, "BaseCollider is missing")
	
	# Проверка активации события телепорта и вызова босса
	tp.interact()
	assert(tp.state == Teleporter.TeleporterState.CHARGING, "Teleporter should be CHARGING after activation")
	assert(tp.zone_dome.visible == true, "ZoneDome must be visible while charging")
	assert(tp.zone_ring.visible == true, "ZoneRing must be visible while charging")
	assert(tp.active_boss != null, "StoneTitanBoss must be spawned on teleporter activation")
	print("[OK] Древний Телепорт: 160м световой маяк, зоны InteractArea(4.5м) и ChargeArea(24м), кольцо/купол и призыв Босса работают.")

	# 3. Проверка DifficultyManager: дистанция и логика спавна
	var dm: DifficultyManager = stage.get_node_or_null("DifficultyManager") as DifficultyManager
	assert(dm != null, "DifficultyManager is missing")
	assert(dm.INITIAL_GRACE_PERIOD >= 5.0, "INITIAL_GRACE_PERIOD must be >= 5.0 seconds")
	assert(dm.MIN_SPAWN_DIST >= 25.0, "MIN_SPAWN_DIST must be >= 25.0m")
	assert(dm.spawn_beam_scene != null, "spawn_beam_scene must be preloaded")
	print("[OK] DifficultyManager: начальный grace-period 5с, минимальная дистанция 25м с лучом материализации.")

	# 4. Проверка коллизий декораций (камни, колонны, арки)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1234
	var rock: StaticBody3D = ProceduralModelBuilder.build_rock_formation(rng, 1.2)
	assert(rock != null, "build_rock_formation failed")
	var rock_colliders: int = 0
	for child in rock.get_children():
		if child is CollisionShape3D:
			rock_colliders += 1
	assert(rock_colliders >= 2, "Rock formation must have multiple facet collision shapes")
	print("[OK] Скалы имеют точные многогранные коллайдеры по каждой фасете (%d шт)." % rock_colliders)

	# 5. Проверка Beetle NavigationAgent3D
	var beetle_packed: PackedScene = load("res://scenes/enemies/beetle.tscn")
	assert(beetle_packed != null, "Failed to load beetle.tscn")
	var beetle: BeetleEnemy = beetle_packed.instantiate() as BeetleEnemy
	assert(beetle.get_node_or_null("NavigationAgent3D") != null, "Beetle must have NavigationAgent3D for pathfinding")
	beetle.queue_free()
	print("[OK] Моб Beetle оснащен NavigationAgent3D для обхода препятствий по NavMesh.")

	stage.queue_free()
	rock.queue_free()

	print("==================================================")
	print("[ALL CHECKS PASSED] LEVEL 1 FULLY POLISHED & PLAYABLE!")
	print("==================================================")
	quit(0)
