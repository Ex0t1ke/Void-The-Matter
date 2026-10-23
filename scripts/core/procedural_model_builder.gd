class_name ProceduralModelBuilder
extends RefCounted
## Процедурный конструктор высокодетализированных составных 3D-моделей в стиле Risk of Rain 2.
## Создаёт модели с 12+ деталями, неоновыми вставками, Rim-подсветкой силуэтов и материалами.
## Полностью исключает примитивные чёрные коробки!

const COLOR_TITANIUM: Color = Color(0.78, 0.84, 0.92, 1.0)
const COLOR_ARMOR_DARK: Color = Color(0.22, 0.25, 0.32, 1.0)
const COLOR_JOINTS: Color = Color(0.35, 0.38, 0.42, 1.0)
const COLOR_NEON_CYAN: Color = Color(0.15, 0.9, 1.0, 1.0)
const COLOR_NEON_ORANGE: Color = Color(1.0, 0.55, 0.1, 1.0)
const COLOR_CHITIN: Color = Color(0.36, 0.22, 0.14, 1.0)
const COLOR_CHITIN_PLATE: Color = Color(0.25, 0.15, 0.1, 1.0)
const COLOR_BIO_LUM: Color = Color(0.2, 1.0, 0.4, 1.0)
const COLOR_STONE: Color = Color(0.28, 0.26, 0.32, 1.0)
const COLOR_STONE_DARK: Color = Color(0.18, 0.16, 0.22, 1.0)
const COLOR_RUNE_GLOW: Color = Color(1.0, 0.25, 0.1, 1.0)


# ==========================================
# 1. COMMANDO (16+ деталей, титановый костюм, реактор, пояс, наколенники, джетпак на +Z, 2 бластера на -Z)
# ==========================================
static func build_commando() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CommandoModel"
	
	# Материалы
	var mat_armor: StandardMaterial3D = _create_material(COLOR_TITANIUM, 0.6, 0.3, true)
	var mat_dark: StandardMaterial3D = _create_material(COLOR_ARMOR_DARK, 0.7, 0.35, true)
	var mat_joints: StandardMaterial3D = _create_material(COLOR_JOINTS, 0.4, 0.6, false)
	var mat_visor: StandardMaterial3D = _create_emissive_material(COLOR_NEON_CYAN, 4.0)
	var mat_reactor: StandardMaterial3D = _create_emissive_material(COLOR_NEON_CYAN, 5.0)
	var mat_thruster: StandardMaterial3D = _create_emissive_material(COLOR_NEON_ORANGE, 4.0)
	var mat_rifle: StandardMaterial3D = _create_material(Color(0.15, 0.16, 0.2), 0.85, 0.25, true)
	
	# 1. Торс (Броня)
	var torso: MeshInstance3D = _make_box(Vector3(0.56, 0.52, 0.36), mat_armor, Vector3(0, 1.15, 0), "Torso")
	root.add_child(torso)
	
	# 2. Нагрудная бронепластина
	var chest_plate: MeshInstance3D = _make_box(Vector3(0.48, 0.36, 0.10), mat_dark, Vector3(0, 1.20, -0.19), "ChestPlate")
	root.add_child(chest_plate)
	
	# 3. Нагрудный светящийся реактор (ядро) на груди (-Z)
	var reactor: MeshInstance3D = _make_cylinder(0.10, 0.08, mat_reactor, Vector3(0, 1.22, -0.24), "ChestReactor")
	reactor.rotation.x = deg_to_rad(90.0)
	root.add_child(reactor)
	
	# 4. Пояс и тазовый сегмент
	var belt: MeshInstance3D = _make_box(Vector3(0.54, 0.14, 0.38), mat_dark, Vector3(0, 0.86, 0), "Belt")
	var pelvis: MeshInstance3D = _make_box(Vector3(0.44, 0.16, 0.32), mat_joints, Vector3(0, 0.76, 0), "Pelvis")
	root.add_child(belt)
	root.add_child(pelvis)
	
	# 5. Скошенный sci-fi шлем
	var helmet: MeshInstance3D = _make_box(Vector3(0.42, 0.38, 0.42), mat_armor, Vector3(0, 1.58, 0), "Helmet")
	root.add_child(helmet)
	
	# 6. Светящийся визор (спереди, z < 0, смотрит на -Z)
	var visor: MeshInstance3D = _make_box(Vector3(0.36, 0.14, 0.10), mat_visor, Vector3(0, 1.58, -0.21), "Visor")
	root.add_child(visor)
	
	# 7, 8. Наплечники (бронещитки)
	var shoulder_l: MeshInstance3D = _make_box(Vector3(0.20, 0.16, 0.26), mat_dark, Vector3(-0.36, 1.36, 0), "ShoulderL")
	var shoulder_r: MeshInstance3D = _make_box(Vector3(0.20, 0.16, 0.26), mat_dark, Vector3(0.36, 1.36, 0), "ShoulderR")
	root.add_child(shoulder_l)
	root.add_child(shoulder_r)
	
	# 9. Рельефный ранец-джетпак за спиной (+Z) с двумя соплами
	var jetpack: MeshInstance3D = _make_box(Vector3(0.44, 0.50, 0.22), mat_dark, Vector3(0, 1.22, 0.22), "Jetpack")
	var jetpack_core: MeshInstance3D = _make_box(Vector3(0.26, 0.32, 0.08), mat_armor, Vector3(0, 1.24, 0.33), "JetpackPlate")
	root.add_child(jetpack)
	root.add_child(jetpack_core)
	
	var nozzle_l: MeshInstance3D = _make_cylinder(0.07, 0.22, mat_thruster, Vector3(-0.14, 0.94, 0.26), "ThrusterL")
	var nozzle_r: MeshInstance3D = _make_cylinder(0.07, 0.22, mat_thruster, Vector3(0.14, 0.94, 0.26), "ThrusterR")
	root.add_child(nozzle_l)
	root.add_child(nozzle_r)
	
	# 10, 11. Руки с суставами в плечах и бластерами, направленными вперёд (-Z)
	var arm_pivot_l: Node3D = Node3D.new()
	arm_pivot_l.name = "ArmPivotL"
	arm_pivot_l.position = Vector3(-0.36, 1.30, 0)
	var arm_l: MeshInstance3D = _make_cylinder(0.07, 0.34, mat_joints, Vector3(0, -0.17, 0), "ArmL")
	var forearm_l: MeshInstance3D = _make_box(Vector3(0.14, 0.22, 0.16), mat_armor, Vector3(0, -0.36, -0.05), "ForearmL")
	var blaster_l: MeshInstance3D = _make_box(Vector3(0.10, 0.16, 0.44), mat_rifle, Vector3(0, -0.38, -0.24), "BlasterL")
	var barrel_l: MeshInstance3D = _make_cylinder(0.035, 0.14, mat_visor, Vector3(0, -0.38, -0.46), "BarrelL")
	barrel_l.rotation.x = deg_to_rad(90.0)
	var muzzle_l: Marker3D = Marker3D.new()
	muzzle_l.name = "MuzzleL"
	muzzle_l.position = Vector3(0, -0.38, -0.54)
	arm_pivot_l.add_child(arm_l)
	arm_pivot_l.add_child(forearm_l)
	arm_pivot_l.add_child(blaster_l)
	arm_pivot_l.add_child(barrel_l)
	arm_pivot_l.add_child(muzzle_l)
	root.add_child(arm_pivot_l)
	
	var arm_pivot_r: Node3D = Node3D.new()
	arm_pivot_r.name = "ArmPivotR"
	arm_pivot_r.position = Vector3(0.36, 1.30, 0)
	var arm_r: MeshInstance3D = _make_cylinder(0.07, 0.34, mat_joints, Vector3(0, -0.17, 0), "ArmR")
	var forearm_r: MeshInstance3D = _make_box(Vector3(0.14, 0.22, 0.16), mat_armor, Vector3(0, -0.36, -0.05), "ForearmR")
	var blaster_r: MeshInstance3D = _make_box(Vector3(0.10, 0.16, 0.44), mat_rifle, Vector3(0, -0.38, -0.24), "BlasterR")
	var barrel_r: MeshInstance3D = _make_cylinder(0.035, 0.14, mat_visor, Vector3(0, -0.38, -0.46), "BarrelR")
	barrel_r.rotation.x = deg_to_rad(90.0)
	var muzzle_r: Marker3D = Marker3D.new()
	muzzle_r.name = "MuzzleR"
	muzzle_r.position = Vector3(0, -0.38, -0.54)
	arm_pivot_r.add_child(arm_r)
	arm_pivot_r.add_child(forearm_r)
	arm_pivot_r.add_child(blaster_r)
	arm_pivot_r.add_child(barrel_r)
	arm_pivot_r.add_child(muzzle_r)
	root.add_child(arm_pivot_r)
	
	# 12, 13. Ноги: шарнир бедра, наколенники и ботинки (подошва ровно в y = 0.0)
	var leg_pivot_l: Node3D = Node3D.new()
	leg_pivot_l.name = "LegPivotL"
	leg_pivot_l.position = Vector3(-0.18, 0.74, 0)
	var thigh_l: MeshInstance3D = _make_cylinder(0.09, 0.32, mat_joints, Vector3(0, -0.16, 0), "LegL")
	var knee_l: MeshInstance3D = _make_box(Vector3(0.16, 0.12, 0.10), mat_dark, Vector3(0, -0.32, -0.09), "KneePadL")
	var shin_l: MeshInstance3D = _make_cylinder(0.08, 0.30, mat_joints, Vector3(0, -0.48, 0), "ShinL")
	var boot_l: MeshInstance3D = _make_box(Vector3(0.18, 0.14, 0.30), mat_armor, Vector3(0, -0.67, -0.04), "BootL")
	leg_pivot_l.add_child(thigh_l)
	leg_pivot_l.add_child(knee_l)
	leg_pivot_l.add_child(shin_l)
	leg_pivot_l.add_child(boot_l)
	root.add_child(leg_pivot_l)
	
	var leg_pivot_r: Node3D = Node3D.new()
	leg_pivot_r.name = "LegPivotR"
	leg_pivot_r.position = Vector3(0.18, 0.74, 0)
	var thigh_r: MeshInstance3D = _make_cylinder(0.09, 0.32, mat_joints, Vector3(0, -0.16, 0), "LegR")
	var knee_r: MeshInstance3D = _make_box(Vector3(0.16, 0.12, 0.10), mat_dark, Vector3(0, -0.32, -0.09), "KneePadR")
	var shin_r: MeshInstance3D = _make_cylinder(0.08, 0.30, mat_joints, Vector3(0, -0.48, 0), "ShinR")
	var boot_r: MeshInstance3D = _make_box(Vector3(0.18, 0.14, 0.30), mat_armor, Vector3(0, -0.67, -0.04), "BootR")
	leg_pivot_r.add_child(thigh_r)
	leg_pivot_r.add_child(knee_r)
	leg_pivot_r.add_child(shin_r)
	leg_pivot_r.add_child(boot_r)
	root.add_child(leg_pivot_r)
	
	return root


# ==========================================
# 2. BEETLE (Сегментированный панцирь, жвалы, 4 глаза, 6 суставчатых лап)
# ==========================================
static func build_beetle() -> Node3D:
	if ResourceLoader.exists("res://assets/models/beetle.glb"):
		var glb: PackedScene = load("res://assets/models/beetle.glb") as PackedScene
		if glb:
			var inst: Node3D = glb.instantiate() as Node3D
			_apply_rim_lighting(inst)
			return inst
			
	var root: Node3D = Node3D.new()
	root.name = "BeetleModel"
	
	var mat_chitin: StandardMaterial3D = _create_material(COLOR_CHITIN, 0.3, 0.4, true)
	var mat_plate: StandardMaterial3D = _create_material(COLOR_CHITIN_PLATE, 0.4, 0.35, true)
	var mat_vein: StandardMaterial3D = _create_emissive_material(COLOR_BIO_LUM, 3.5)
	
	# Сегменты панциря
	var abdomen: MeshInstance3D = _make_box(Vector3(1.3, 0.75, 1.6), mat_chitin, Vector3(0, 0.6, 0.1), "CarapaceMain")
	var plate1: MeshInstance3D = _make_box(Vector3(1.15, 0.15, 1.4), mat_plate, Vector3(0, 0.98, 0.1), "CarapacePlate")
	var vein: MeshInstance3D = _make_box(Vector3(0.14, 0.18, 1.45), mat_vein, Vector3(0, 1.0, 0.1), "BioVein")
	root.add_child(abdomen)
	root.add_child(plate1)
	root.add_child(vein)
	
	# Голова и жвалы
	var head: MeshInstance3D = _make_box(Vector3(0.7, 0.5, 0.6), mat_plate, Vector3(0, 0.5, -0.85), "Head")
	var mand_l: MeshInstance3D = _make_box(Vector3(0.12, 0.15, 0.55), mat_chitin, Vector3(-0.32, 0.4, -1.25), "MandibleL")
	var mand_r: MeshInstance3D = _make_box(Vector3(0.12, 0.15, 0.55), mat_chitin, Vector3(0.32, 0.4, -1.25), "MandibleR")
	mand_l.rotation.y = deg_to_rad(20.0)
	mand_r.rotation.y = deg_to_rad(-20.0)
	root.add_child(head)
	root.add_child(mand_l)
	root.add_child(mand_r)
	
	# 4 светящихся глаза
	for ex in [-0.22, 0.22]:
		for ey in [0.55, 0.42]:
			var eye: MeshInstance3D = _make_box(Vector3(0.08, 0.08, 0.08), mat_vein, Vector3(ex, ey, -1.15), "Eye")
			root.add_child(eye)
			
	# 6 лап (составные суставы)
	for i in range(3):
		var z_pos: float = -0.4 + i * 0.55
		for side in [-1.0, 1.0]:
			var leg: MeshInstance3D = _make_cylinder(0.07, 0.85, mat_plate, Vector3(side * 0.9, 0.35, z_pos), "Leg_%d_%d" % [i, int(side)])
			leg.rotation.z = deg_to_rad(side * 35.0)
			root.add_child(leg)
			
	return root


# ==========================================
# 3. WISP (Древняя рогатая маска, 2 вращающихся кольца рун, пылающее ядро)
# ==========================================
static func build_wisp() -> Node3D:
	if ResourceLoader.exists("res://assets/models/wisp.glb"):
		var glb: PackedScene = load("res://assets/models/wisp.glb") as PackedScene
		if glb:
			var inst: Node3D = glb.instantiate() as Node3D
			_apply_rim_lighting(inst)
			return inst
			
	var root: Node3D = Node3D.new()
	root.name = "WispModel"
	
	var mat_mask: StandardMaterial3D = _create_material(COLOR_STONE, 0.8, 0.4, true)
	var mat_flame: StandardMaterial3D = _create_emissive_material(COLOR_NEON_ORANGE, 4.5)
	var mat_rune: StandardMaterial3D = _create_emissive_material(Color(1.0, 0.7, 0.15), 3.0)
	
	# Пылающее ядро
	var core: MeshInstance3D = _make_cylinder(0.45, 0.7, mat_flame, Vector3(0, 0, 0), "Core")
	root.add_child(core)
	
	# Древняя каменная маска
	var mask: MeshInstance3D = _make_box(Vector3(0.75, 0.9, 0.22), mat_mask, Vector3(0, 0, -0.42), "Mask")
	var horn_l: MeshInstance3D = _make_box(Vector3(0.14, 0.6, 0.14), mat_mask, Vector3(-0.35, 0.65, -0.42), "HornL")
	var horn_r: MeshInstance3D = _make_box(Vector3(0.14, 0.6, 0.14), mat_mask, Vector3(0.35, 0.65, -0.42), "HornR")
	horn_l.rotation.z = deg_to_rad(25.0)
	horn_r.rotation.z = deg_to_rad(-25.0)
	root.add_child(mask)
	root.add_child(horn_l)
	root.add_child(horn_r)
	
	# Глазницы маски (светящиеся)
	var eye_l: MeshInstance3D = _make_box(Vector3(0.18, 0.12, 0.1), mat_flame, Vector3(-0.2, 0.1, -0.52), "MaskEyeL")
	var eye_r: MeshInstance3D = _make_box(Vector3(0.18, 0.12, 0.1), mat_flame, Vector3(0.2, 0.1, -0.52), "MaskEyeR")
	root.add_child(eye_l)
	root.add_child(eye_r)
	
	# 2 вращающихся кольца рун
	var ring1: MeshInstance3D = _make_torus(0.9, 0.05, mat_rune, Vector3.ZERO, "RuneRingOuter")
	var ring2: MeshInstance3D = _make_torus(0.7, 0.04, mat_rune, Vector3.ZERO, "RuneRingInner")
	ring2.rotation.x = deg_to_rad(45.0)
	root.add_child(ring1)
	root.add_child(ring2)
	
	return root


# ==========================================
# 4. STONE TITAN (Колосс из 16+ деталей, тёмный базальт, ядро в груди, лазерное око, молоты-кулаки)
# ==========================================
static func build_stone_titan() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "StoneTitanModel"
	
	var mat_stone: StandardMaterial3D = _create_material(COLOR_STONE, 0.2, 0.85, true)
	var mat_dark: StandardMaterial3D = _create_material(COLOR_STONE_DARK, 0.35, 0.9, true)
	var mat_eye: StandardMaterial3D = _create_emissive_material(Color(1.0, 0.1, 0.05), 6.5)
	var mat_rune: StandardMaterial3D = _create_emissive_material(COLOR_RUNE_GLOW, 4.5)
	
	# 1. Тазовый сегмент (массивное основание торса)
	var pelvis: MeshInstance3D = _make_box(Vector3(3.6, 1.0, 2.4), mat_dark, Vector3(0, 3.8, 0), "Pelvis")
	root.add_child(pelvis)
	
	# 2, 3. Слоистый торс из плит базальта
	var torso_lower: MeshInstance3D = _make_box(Vector3(4.0, 1.3, 2.8), mat_stone, Vector3(0, 4.9, 0), "TorsoLower")
	var torso_upper: MeshInstance3D = _make_box(Vector3(4.6, 1.7, 3.2), mat_dark, Vector3(0, 6.3, 0), "TorsoUpper")
	root.add_child(torso_lower)
	root.add_child(torso_upper)
	
	# 4. Светящееся ядро в груди со светом OmniLight3D
	var chest_core: MeshInstance3D = _make_cylinder(0.55, 0.3, mat_rune, Vector3(0, 6.1, -1.6), "ChestCore")
	chest_core.rotation.x = deg_to_rad(90.0)
	root.add_child(chest_core)
	
	var core_light: OmniLight3D = OmniLight3D.new()
	core_light.name = "ChestCoreLight"
	core_light.light_color = Color(1.0, 0.35, 0.1)
	core_light.light_energy = 4.0
	core_light.omni_range = 10.0
	core_light.position = Vector3(0, 6.1, -1.8)
	root.add_child(core_light)
	
	# 5, 6, 7. Рунические разломы на груди
	var crack1: MeshInstance3D = _make_box(Vector3(0.25, 2.2, 0.15), mat_rune, Vector3(0.7, 5.9, -1.58), "RuneCrack1")
	var crack2: MeshInstance3D = _make_box(Vector3(1.8, 0.25, 0.15), mat_rune, Vector3(-0.6, 5.4, -1.58), "RuneCrack2")
	var crack3: MeshInstance3D = _make_box(Vector3(0.22, 1.6, 0.15), mat_rune, Vector3(-1.2, 6.1, -1.58), "RuneCrack3")
	root.add_child(crack1)
	root.add_child(crack2)
	root.add_child(crack3)
	
	# 8. Монолитная голова
	var head: MeshInstance3D = _make_box(Vector3(1.9, 1.8, 1.9), mat_dark, Vector3(0, 7.8, -0.2), "Head")
	root.add_child(head)
	
	# 9. Пылающее лазерное око с мощным OmniLight3D
	var eye: MeshInstance3D = _make_cylinder(0.44, 0.35, mat_eye, Vector3(0, 7.8, -1.18), "LaserEye")
	eye.rotation.x = deg_to_rad(90.0)
	root.add_child(eye)
	
	var eye_light: OmniLight3D = OmniLight3D.new()
	eye_light.name = "TitanEyeLight"
	eye_light.light_color = Color(1.0, 0.15, 0.05)
	eye_light.light_energy = 5.5
	eye_light.omni_range = 16.0
	eye_light.position = Vector3(0, 7.8, -1.4)
	root.add_child(eye_light)
	
	# 10, 11. Парящие рунические монолиты-наплечники
	var shoulder_l: MeshInstance3D = _make_box(Vector3(1.8, 3.0, 2.0), mat_stone, Vector3(-3.4, 7.0, 0), "ShoulderMonolithL")
	var shoulder_r: MeshInstance3D = _make_box(Vector3(1.8, 3.0, 2.0), mat_stone, Vector3(3.4, 7.0, 0), "ShoulderMonolithR")
	var sh_rune_l: MeshInstance3D = _make_box(Vector3(0.2, 2.4, 2.05), mat_rune, Vector3(-3.4, 7.0, 0), "ShoulderRuneL")
	var sh_rune_r: MeshInstance3D = _make_box(Vector3(0.2, 2.4, 2.05), mat_rune, Vector3(3.4, 7.0, 0), "ShoulderRuneR")
	shoulder_l.rotation.z = deg_to_rad(14.0)
	shoulder_r.rotation.z = deg_to_rad(-14.0)
	sh_rune_l.rotation.z = deg_to_rad(14.0)
	sh_rune_r.rotation.z = deg_to_rad(-14.0)
	root.add_child(shoulder_l)
	root.add_child(shoulder_r)
	root.add_child(sh_rune_l)
	root.add_child(sh_rune_r)
	
	# 12, 13. Ноги-колонны с шарнирами в бёдрах (ступни ровно в y = 0.0)
	var leg_pivot_l: Node3D = Node3D.new()
	leg_pivot_l.name = "LegPivotL"
	leg_pivot_l.position = Vector3(-1.6, 3.8, 0)
	var thigh_l: MeshInstance3D = _make_cylinder(0.7, 1.8, mat_dark, Vector3(0, -0.9, 0), "ThighL")
	var knee_l: MeshInstance3D = _make_box(Vector3(1.5, 0.6, 1.5), mat_stone, Vector3(0, -1.8, -0.1), "KneeL")
	var shin_l: MeshInstance3D = _make_cylinder(0.65, 1.8, mat_dark, Vector3(0, -2.7, 0), "ShinL")
	var foot_l: MeshInstance3D = _make_box(Vector3(1.6, 0.6, 2.4), mat_dark, Vector3(0, -3.5, -0.3), "FootL")
	leg_pivot_l.add_child(thigh_l)
	leg_pivot_l.add_child(knee_l)
	leg_pivot_l.add_child(shin_l)
	leg_pivot_l.add_child(foot_l)
	root.add_child(leg_pivot_l)
	
	var leg_pivot_r: Node3D = Node3D.new()
	leg_pivot_r.name = "LegPivotR"
	leg_pivot_r.position = Vector3(1.6, 3.8, 0)
	var thigh_r: MeshInstance3D = _make_cylinder(0.7, 1.8, mat_dark, Vector3(0, -0.9, 0), "ThighR")
	var knee_r: MeshInstance3D = _make_box(Vector3(1.5, 0.6, 1.5), mat_stone, Vector3(0, -1.8, -0.1), "KneeR")
	var shin_r: MeshInstance3D = _make_cylinder(0.65, 1.8, mat_dark, Vector3(0, -2.7, 0), "ShinR")
	var foot_r: MeshInstance3D = _make_box(Vector3(1.6, 0.6, 2.4), mat_dark, Vector3(0, -3.5, -0.3), "FootR")
	leg_pivot_r.add_child(thigh_r)
	leg_pivot_r.add_child(knee_r)
	leg_pivot_r.add_child(shin_r)
	leg_pivot_r.add_child(foot_r)
	root.add_child(leg_pivot_r)
	
	# 14, 15. Руки-молоты с шарнирами в плечах
	var arm_pivot_l: Node3D = Node3D.new()
	arm_pivot_l.name = "ArmPivotL"
	arm_pivot_l.position = Vector3(-2.8, 6.2, 0)
	var u_arm_l: MeshInstance3D = _make_cylinder(0.55, 1.8, mat_dark, Vector3(0, -0.9, 0), "UpperArmL")
	var f_arm_l: MeshInstance3D = _make_box(Vector3(1.3, 1.6, 1.3), mat_stone, Vector3(0, -2.2, -0.1), "ForearmL")
	var fist_l: MeshInstance3D = _make_box(Vector3(1.8, 1.5, 1.8), mat_dark, Vector3(0, -3.4, -0.1), "FistL")
	var rune_l: MeshInstance3D = _make_box(Vector3(0.25, 1.3, 1.85), mat_rune, Vector3(0, -3.4, -0.1), "FistRuneL")
	arm_pivot_l.add_child(u_arm_l)
	arm_pivot_l.add_child(f_arm_l)
	arm_pivot_l.add_child(fist_l)
	arm_pivot_l.add_child(rune_l)
	root.add_child(arm_pivot_l)
	
	var arm_pivot_r: Node3D = Node3D.new()
	arm_pivot_r.name = "ArmPivotR"
	arm_pivot_r.position = Vector3(2.8, 6.2, 0)
	var u_arm_r: MeshInstance3D = _make_cylinder(0.55, 1.8, mat_dark, Vector3(0, -0.9, 0), "UpperArmR")
	var f_arm_r: MeshInstance3D = _make_box(Vector3(1.3, 1.6, 1.3), mat_stone, Vector3(0, -2.2, -0.1), "ForearmR")
	var fist_r: MeshInstance3D = _make_box(Vector3(1.8, 1.5, 1.8), mat_dark, Vector3(0, -3.4, -0.1), "FistR")
	var rune_r: MeshInstance3D = _make_box(Vector3(0.25, 1.3, 1.85), mat_rune, Vector3(0, -3.4, -0.1), "FistRuneR")
	arm_pivot_r.add_child(u_arm_r)
	arm_pivot_r.add_child(f_arm_r)
	arm_pivot_r.add_child(fist_r)
	arm_pivot_r.add_child(rune_r)
	root.add_child(arm_pivot_r)
	
	return root


# ==========================================
# 5. SCI-FI CHEST (Ребристый корпус, шарнирная крышка, неоновый замок и голограмма)
# ==========================================
static func build_chest() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "SciFiChestModel"
	
	var mat_body: StandardMaterial3D = _create_material(Color(0.85, 0.48, 0.12), 0.7, 0.35, true)
	var mat_rim: StandardMaterial3D = _create_material(Color(0.18, 0.20, 0.26), 0.85, 0.28, true)
	var mat_neon: StandardMaterial3D = _create_emissive_material(COLOR_NEON_ORANGE, 4.5)
	var mat_holo: StandardMaterial3D = _create_emissive_material(COLOR_NEON_CYAN, 3.0)
	
	# Основание с рёбрами
	var base: MeshInstance3D = _make_box(Vector3(1.5, 0.58, 1.1), mat_body, Vector3(0, 0.29, 0), "Base")
	var rib1: MeshInstance3D = _make_box(Vector3(1.56, 0.62, 0.16), mat_rim, Vector3(0, 0.31, -0.36), "Rib1")
	var rib2: MeshInstance3D = _make_box(Vector3(1.56, 0.62, 0.16), mat_rim, Vector3(0, 0.31, 0.36), "Rib2")
	var lock_light: MeshInstance3D = _make_box(Vector3(0.38, 0.16, 0.1), mat_neon, Vector3(0, 0.45, -0.56), "LockIndicator")
	root.add_child(base)
	root.add_child(rib1)
	root.add_child(rib2)
	root.add_child(lock_light)
	
	# Голографический луч стоимости сверху
	var holo: MeshInstance3D = _make_cylinder(0.25, 0.04, mat_holo, Vector3(0, 0.75, 0), "HoloEmitter")
	root.add_child(holo)
	
	# Шарнирная крышка с правильной осью вращения сзади
	var lid_hinge: Node3D = Node3D.new()
	lid_hinge.name = "Lid"
	lid_hinge.position = Vector3(0, 0.58, 0.52)
	var lid_mesh: MeshInstance3D = _make_box(Vector3(1.52, 0.32, 1.12), mat_rim, Vector3(0, 0.16, -0.52), "LidMesh")
	var lid_trim: MeshInstance3D = _make_box(Vector3(1.3, 0.08, 0.9), mat_body, Vector3(0, 0.33, -0.52), "LidTrim")
	lid_hinge.add_child(lid_mesh)
	lid_hinge.add_child(lid_trim)
	root.add_child(lid_hinge)
	
	return root


# ==========================================
# 6. TELEPORTER (Ступенчатая платформа, 4 изогнутых обелиска, кристалл, световой столб)
# ==========================================
static func build_teleporter() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "TeleporterModel"
	
	var mat_stone: StandardMaterial3D = _create_material(COLOR_STONE_DARK, 0.2, 0.85, true)
	var mat_rune: StandardMaterial3D = _create_emissive_material(COLOR_NEON_ORANGE, 4.5)
	
	# 1. Ступенчатая платформа
	var step1: MeshInstance3D = _make_cylinder(3.8, 0.3, mat_stone, Vector3(0, 0.15, 0), "Step1")
	var step2: MeshInstance3D = _make_cylinder(2.6, 0.3, mat_stone, Vector3(0, 0.45, 0), "Step2")
	var rune_ring: MeshInstance3D = _make_torus(2.3, 0.08, mat_rune, Vector3(0, 0.62, 0), "RuneRing")
	root.add_child(step1)
	root.add_child(step2)
	root.add_child(rune_ring)
	
	# 2. Четыре изогнутых обелиска со светящимися рунами
	for i in range(4):
		var angle: float = i * PI * 0.5 + PI * 0.25
		var pos: Vector3 = Vector3(cos(angle) * 2.8, 3.0, sin(angle) * 2.8)
		var obelisk: MeshInstance3D = _make_box(Vector3(0.65, 5.5, 0.65), mat_stone, pos, "Obelisk_%d" % i)
		obelisk.rotation.y = angle
		obelisk.rotation.z = deg_to_rad(-12.0)
		var rune_stripe: MeshInstance3D = _make_box(Vector3(0.12, 4.5, 0.68), mat_rune, pos, "ObeliskRune_%d" % i)
		rune_stripe.rotation.y = angle
		rune_stripe.rotation.z = deg_to_rad(-12.0)
		root.add_child(obelisk)
		root.add_child(rune_stripe)
		
	# 3. Парящий кристалл в центре
	var crystal: MeshInstance3D = _make_cylinder(0.45, 1.6, mat_rune, Vector3(0, 3.2, 0), "FloatingCrystal")
	root.add_child(crystal)
	
	# 4. Световой столб в небо
	var sky_beam: MeshInstance3D = _make_cylinder(0.35, 120.0, mat_rune, Vector3(0, 60.0, 0), "SkyBeacon")
	root.add_child(sky_beam)
	
	return root


# ==========================================
# 7. ИНОПЛАНЕТНОЕ ДЕРЕВО (Искривленный ствол, биолюминесцентная крона)
# ==========================================
static func build_alien_tree(rng: RandomNumberGenerator) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "AlienTree"
	
	var mat_bark: StandardMaterial3D = _create_material(Color(0.14, 0.12, 0.18), 0.1, 0.9, true)
	var mat_foliage: StandardMaterial3D = _create_emissive_material(Color(0.12, 0.85, 0.72), 2.5)
	var mat_foliage_amber: StandardMaterial3D = _create_emissive_material(Color(1.0, 0.65, 0.15), 2.8)
	var use_amber: bool = rng.randf() > 0.6
	var canopy_mat: StandardMaterial3D = mat_foliage_amber if use_amber else mat_foliage
	
	# Ствол из 3 искривленных сегментов
	var trunk1: MeshInstance3D = _make_cylinder(0.38, 2.8, mat_bark, Vector3(0, 1.4, 0), "Trunk1")
	var trunk2: MeshInstance3D = _make_cylinder(0.28, 2.6, mat_bark, Vector3(0.3, 3.8, 0.2), "Trunk2")
	trunk2.rotation.z = deg_to_rad(14.0)
	var trunk3: MeshInstance3D = _make_cylinder(0.22, 2.2, mat_bark, Vector3(0.7, 5.6, 0.5), "Trunk3")
	trunk3.rotation.x = deg_to_rad(-16.0)
	trunk3.rotation.z = deg_to_rad(18.0)
	root.add_child(trunk1)
	root.add_child(trunk2)
	root.add_child(trunk3)
	
	# 3 яруса светящейся кроны-зонтика
	var c1: MeshInstance3D = _make_cylinder(2.2, 0.6, canopy_mat, Vector3(0.9, 6.4, 0.6), "Canopy1")
	var c2: MeshInstance3D = _make_cylinder(1.6, 0.5, canopy_mat, Vector3(1.0, 7.1, 0.7), "Canopy2")
	var c3: MeshInstance3D = _make_cylinder(0.9, 0.4, canopy_mat, Vector3(1.05, 7.7, 0.75), "Canopy3")
	root.add_child(c1)
	root.add_child(c2)
	root.add_child(c3)
	
	# Мягкое свечение под кроной
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color(0.15, 0.9, 0.75) if not use_amber else Color(1.0, 0.6, 0.2)
	light.light_energy = 1.4
	light.omni_range = 6.0
	light.position = Vector3(0.9, 5.8, 0.6)
	root.add_child(light)
	
	return root


# ==========================================
# 8. ДЕСАНТНАЯ КАПСУЛА (Drop Pod на спавне игрока)
# ==========================================
static func build_drop_pod() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "DropPod"
	
	var mat_hull: StandardMaterial3D = _create_material(Color(0.22, 0.25, 0.32), 0.8, 0.35, true)
	var mat_heat: StandardMaterial3D = _create_material(Color(0.10, 0.10, 0.12), 0.3, 0.85, false)
	var mat_beacon: StandardMaterial3D = _create_emissive_material(Color(1.0, 0.7, 0.1), 5.0)
	
	# Обожжённый термощит
	var heat_shield: MeshInstance3D = _make_cylinder(1.6, 0.35, mat_heat, Vector3(0, 0.18, 0), "HeatShield")
	root.add_child(heat_shield)
	
	# Корпус капсулы
	var hull: MeshInstance3D = _make_cylinder(0.85, 2.6, mat_hull, Vector3(0, 1.5, 0), "Hull")
	root.add_child(hull)
	
	# Открытый шлюз / дверь
	var hatch: MeshInstance3D = _make_box(Vector3(0.95, 1.6, 0.2), mat_heat, Vector3(0, 1.2, -0.9), "HatchDoor")
	hatch.rotation.x = deg_to_rad(30.0)
	root.add_child(hatch)
	
	# Маячок на вершине с мигающим светом
	var beacon: MeshInstance3D = _make_cylinder(0.12, 0.35, mat_beacon, Vector3(0, 2.95, 0), "Beacon")
	root.add_child(beacon)
	
	var bl: OmniLight3D = OmniLight3D.new()
	bl.name = "BeaconLight"
	bl.light_color = Color(1.0, 0.7, 0.15)
	bl.light_energy = 3.0
	bl.omni_range = 8.0
	bl.position = Vector3(0, 3.1, 0)
	root.add_child(bl)
	
	return root


# ==========================================
# 9. ОРГАНИЧЕСКИЕ МНОГОГРАННЫЕ СКАЛЫ (вместо серых кубов BoxMesh)
# ==========================================
static func build_rock_formation(rng: RandomNumberGenerator, scale_mult: float = 1.0) -> StaticBody3D:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.name = "RockFormation"
	sb.collision_layer = 1
	sb.collision_mask = 7
	
	var mat_basalt: StandardMaterial3D = _create_material(Color(0.16, 0.15, 0.22), 0.2, 0.92, false)
	var mat_moss: StandardMaterial3D = _create_material(Color(0.14, 0.22, 0.25), 0.1, 0.95, false)
	
	# Композитная многогранная скала из 3-4 пересекающихся блоков
	var num_rocks: int = rng.randi_range(2, 4)
	for i in range(num_rocks):
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "RockFacet_%d" % i
		var cm: CylinderMesh = CylinderMesh.new()
		cm.radial_segments = rng.randi_range(6, 8) # чёткие многогранные скосы
		cm.top_radius = rng.randf_range(1.2, 2.2) * scale_mult
		cm.bottom_radius = rng.randf_range(1.8, 3.2) * scale_mult
		cm.height = rng.randf_range(2.8, 5.5) * scale_mult
		mi.mesh = cm
		mi.position = Vector3(
			rng.randf_range(-1.2, 1.2) * scale_mult,
			cm.height * 0.45,
			rng.randf_range(-1.2, 1.2) * scale_mult
		)
		mi.rotation = Vector3(
			rng.randf_range(-0.15, 0.15),
			rng.randf_range(0.0, TAU),
			rng.randf_range(-0.18, 0.18)
		)
		mi.set_surface_override_material(0, mat_basalt if i > 0 else mat_moss)
		sb.add_child(mi)
		
	# Коллизия
	var cs: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(4.5 * scale_mult, 4.0 * scale_mult, 4.5 * scale_mult)
	cs.shape = shape
	cs.position = Vector3(0, 2.0 * scale_mult, 0)
	sb.add_child(cs)
	
	return sb


# ==========================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ГЕНЕРАЦИИ МЕШЕЙ И МАТЕРИАЛОВ
# ==========================================
static func _make_box(s: Vector3, mat: Material, pos: Vector3, n: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = n
	var bm: BoxMesh = BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	return mi


static func _make_cylinder(r: float, h: float, mat: Material, pos: Vector3, n: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = n
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	return mi


static func _make_torus(r: float, ring_r: float, mat: Material, pos: Vector3, n: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = n
	var tm: TorusMesh = TorusMesh.new()
	tm.inner_radius = r - ring_r
	tm.outer_radius = r + ring_r
	mi.mesh = tm
	mi.position = pos
	mi.set_surface_override_material(0, mat)
	return mi


static func _create_material(color: Color, metallic: float, roughness: float, rim: bool) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if rim:
		mat.rim_enabled = true
		mat.rim = 0.4
		mat.rim_tint = 0.5
	return mat


static func _create_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.rim_enabled = true
	mat.rim = 0.5
	return mat


static func _apply_rim_lighting(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		for i in range(mi.get_surface_override_material_count()):
			var m: Material = mi.get_surface_override_material(i)
			if m is StandardMaterial3D:
				var sm: StandardMaterial3D = m as StandardMaterial3D
				sm.rim_enabled = true
				sm.rim = 0.4
				sm.rim_tint = 0.5
		if mi.mesh:
			for i in range(mi.mesh.get_surface_count()):
				var m: Material = mi.mesh.surface_get_material(i)
				if m is StandardMaterial3D:
					var sm: StandardMaterial3D = m as StandardMaterial3D
					sm.rim_enabled = true
					sm.rim = 0.4
					sm.rim_tint = 0.5
	for child in node.get_children():
		_apply_rim_lighting(child)
