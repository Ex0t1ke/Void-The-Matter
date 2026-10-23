class_name IslandTerrainGenerator
extends StaticBody3D
## Процедурный генератор рельефного 3D-острова (240x240м) в стиле Risk of Void.
## Создает ArrayMesh через SurfaceTool + FastNoiseLite с точной коллизией (ConcavePolygonShape3D)
## и наполняет остров органическими скалами, древними колоннами, инопланетными деревьями,
## десантной капсулой Drop Pod, светящимися кристаллами, морем облаков и парящими островами.

@export var island_size: float = 240.0
@export var grid_step: float = 2.0
@export var max_hill_height: float = 12.0

var noise: FastNoiseLite
var terrain_mesh: ArrayMesh
var jump_pad_scene: PackedScene = preload("res://scenes/world/jump_pad.tscn")

# Материалы для окружения
var mat_rock: StandardMaterial3D
var mat_crystal_cyan: StandardMaterial3D
var mat_crystal_amber: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1 # Layer 1 (World)
	collision_mask = 7  # Player + Enemies + Projectiles
	
	_init_noise()
	_init_materials()
	_generate_terrain_mesh()
	_scatter_props()
	_align_stage_entities()


func _init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = 1337
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.014
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.45


func _init_materials() -> void:
	# Скальные глыбы для укрытия (темный базальт)
	mat_rock = StandardMaterial3D.new()
	mat_rock.albedo_color = Color(0.18, 0.17, 0.24, 1.0)
	mat_rock.roughness = 0.95
	mat_rock.rim_enabled = false
	
	# Светящиеся кристаллы (Циан)
	mat_crystal_cyan = StandardMaterial3D.new()
	mat_crystal_cyan.albedo_color = Color(0.15, 0.9, 1.0, 1.0)
	mat_crystal_cyan.emission_enabled = true
	mat_crystal_cyan.emission = Color(0.15, 0.9, 1.0, 1.0)
	mat_crystal_cyan.emission_energy_multiplier = 4.2
	mat_crystal_cyan.rim_enabled = true
	mat_crystal_cyan.rim = 0.6
	
	# Светящиеся кристаллы (Янтарь)
	mat_crystal_amber = StandardMaterial3D.new()
	mat_crystal_amber.albedo_color = Color(1.0, 0.6, 0.15, 1.0)
	mat_crystal_amber.emission_enabled = true
	mat_crystal_amber.emission = Color(1.0, 0.55, 0.15, 1.0)
	mat_crystal_amber.emission_energy_multiplier = 4.0
	mat_crystal_amber.rim_enabled = true
	mat_crystal_amber.rim = 0.6


## Точная математическая высота острова в любой координате (X, Z)
func get_height_at(x: float, z: float) -> float:
	if not noise:
		_init_noise()
		
	var d: float = sqrt(x * x + z * z)
	var half_size: float = island_size * 0.5
	if d > half_size:
		return -15.0
		
	# Базовый шум рельефа
	var n_val: float = noise.get_noise_2d(x, z) # [-1..1]
	
	# Центральное ровное плато для спавна и сражений
	if d < 28.0:
		return 2.0 + n_val * 0.8
		
	# Зона холмов, кратеров и возвышенностей (28м .. 95м)
	var hill_factor: float = sin(clampf((d - 28.0) / 67.0, 0.0, 1.0) * PI)
	var raw_h: float = 2.0 + (n_val + 0.3) * max_hill_height * hill_factor
	
	# Небольшой кратер на северо-западе острова
	var crater_dist: float = sqrt((x + 42.0) * (x + 42.0) + (z - 35.0) * (z - 35.0))
	if crater_dist < 22.0:
		raw_h -= (1.0 - crater_dist / 22.0) * 5.5
		
	# Возвышенная гряда на юго-востоке острова
	var ridge_dist: float = sqrt((x - 48.0) * (x - 48.0) + (z + 40.0) * (z + 40.0))
	if ridge_dist < 28.0:
		raw_h += (1.0 - ridge_dist / 28.0) * 6.0
		
	# Плавный спуск по краям острова
	if d > 90.0:
		var edge_t: float = (d - 90.0) / (half_size - 90.0)
		raw_h = lerpf(raw_h, -12.0, edge_t * edge_t)
		
	return maxf(-15.0, raw_h)


## Генерация ArrayMesh террейна с раскраской вершин и точной коллизией
func _generate_terrain_mesh() -> void:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size: float = island_size * 0.5
	var steps: int = int(island_size / grid_step)
	
	# Подготавливаем сетку высот
	var heights: Array = []
	for iz in range(steps + 1):
		var row: Array[float] = []
		var z: float = -half_size + iz * grid_step
		for ix in range(steps + 1):
			var x: float = -half_size + ix * grid_step
			row.append(get_height_at(x, z))
		heights.append(row)
		
	# Строим треугольники сетки
	for iz in range(steps):
		var z0: float = -half_size + iz * grid_step
		var z1: float = z0 + grid_step
		for ix in range(steps):
			var x0: float = -half_size + ix * grid_step
			var x1: float = x0 + grid_step
			
			var h00: float = heights[iz][ix]
			var h10: float = heights[iz][ix + 1]
			var h01: float = heights[iz + 1][ix]
			var h11: float = heights[iz + 1][ix + 1]
			
			var p00: Vector3 = Vector3(x0, h00, z0)
			var p10: Vector3 = Vector3(x1, h10, z0)
			var p01: Vector3 = Vector3(x0, h01, z1)
			var p11: Vector3 = Vector3(x1, h11, z1)
			
			# Нормали для раскраски
			var norm1: Vector3 = ((p10 - p00).cross(p01 - p00)).normalized()
			var norm2: Vector3 = ((p11 - p10).cross(p01 - p10)).normalized()
			
			# Треугольник 1
			_add_terrain_vertex(st, p00, norm1)
			_add_terrain_vertex(st, p10, norm1)
			_add_terrain_vertex(st, p01, norm1)
			
			# Треугольник 2
			_add_terrain_vertex(st, p10, norm2)
			_add_terrain_vertex(st, p11, norm2)
			_add_terrain_vertex(st, p01, norm2)
			
	st.generate_normals()
	st.generate_tangents()
	
	# Создаём материал с поддержкой Vertex Colors
	var mat_terrain: StandardMaterial3D = StandardMaterial3D.new()
	mat_terrain.vertex_color_use_as_albedo = true
	mat_terrain.roughness = 0.92
	mat_terrain.metallic = 0.05
	mat_terrain.rim_enabled = false
	
	terrain_mesh = st.commit()
	terrain_mesh.surface_set_material(0, mat_terrain)
	
	# Создаём MeshInstance3D
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	mesh_inst.name = "TerrainMeshInstance"
	mesh_inst.mesh = terrain_mesh
	add_child(mesh_inst)
	
	# Создаём точную коллизию рельефа (ConcavePolygonShape3D)
	var shape: ConcavePolygonShape3D = terrain_mesh.create_trimesh_shape()
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	col_shape.name = "TerrainCollision"
	col_shape.shape = shape
	add_child(col_shape)


func _add_terrain_vertex(st: SurfaceTool, pos: Vector3, norm: Vector3) -> void:
	# Глубокая тёмная инопланетная палитра
	var col: Color
	if norm.y > 0.82:
		# Ровные участки: тёмно-бирюзовый инопланетный мох
		col = Color(0.14, 0.22, 0.26, 1.0)
	elif norm.y > 0.65:
		# Умеренные склоны: тёмно-синий инопланетный камень
		col = Color(0.16, 0.18, 0.25, 1.0)
	else:
		# Крутые скальные откосы: глубокий тёмно-фиолетовый сланец
		col = Color(0.12, 0.11, 0.17, 1.0)
		
	# Впадины и низины: насыщенная тёмная кристаллическая порода
	if pos.y < 1.2:
		col = Color(0.10, 0.20, 0.24, 1.0)
		
	st.set_color(col)
	st.set_normal(norm)
	st.set_uv(Vector2(pos.x * 0.1, pos.z * 0.1))
	st.add_vertex(pos)


## Наполнение острова: скальные гряды, руины, инопланетные деревья, Drop Pod, кристаллы и гейзеры
func _scatter_props() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	
	var props_root: Node3D = Node3D.new()
	props_root.name = "PropsScatter"
	add_child(props_root)
	
	# 1. Органические многогранные скалы (28 штук вместо BoxMesh)
	for i in range(28):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(16.0, 94.0)
		var px: float = cos(angle) * dist
		var pz: float = sin(angle) * dist
		var py: float = get_height_at(px, pz)
		
		if py > 0.0:
			var scale_mult: float = rng.randf_range(0.9, 1.8)
			var rock_formation: StaticBody3D = ProceduralModelBuilder.build_rock_formation(rng, scale_mult)
			rock_formation.position = Vector3(px, py, pz)
			rock_formation.rotation.y = rng.randf_range(0.0, TAU)
			props_root.add_child(rock_formation)
			
	# 2. Древние руины: расколотые многоступенчатые колонны с капителями (8 штук)
	var column_coords: Array[Vector2] = [
		Vector2(18.0, -14.0),
		Vector2(-22.0, 16.0),
		Vector2(-14.0, -28.0),
		Vector2(32.0, 24.0),
		Vector2(-38.0, -18.0),
		Vector2(45.0, -32.0),
		Vector2(-52.0, 36.0),
		Vector2(26.0, 48.0)
	]
	for c in column_coords:
		var cy: float = get_height_at(c.x, c.y)
		var col: StaticBody3D = _create_ruined_column(rng)
		col.position = Vector3(c.x, cy, c.y)
		col.rotation.y = rng.randf_range(0.0, TAU)
		props_root.add_child(col)
		
	# 3. Каменные древние арки-монолиты (4 крупных укрытия)
	var arch_coords: Array[Vector2] = [
		Vector2(36.0, -24.0),
		Vector2(-42.0, 28.0),
		Vector2(-26.0, -42.0),
		Vector2(50.0, 38.0)
	]
	for c in arch_coords:
		var ay: float = get_height_at(c.x, c.y)
		var arch: StaticBody3D = _create_stone_arch()
		arch.position = Vector3(c.x, ay, c.y)
		arch.rotation.y = rng.randf_range(0.0, PI)
		props_root.add_child(arch)
		
	# 4. Инопланетная флора: искривлённые деревья с биолюминесцентной кроной (20 штук)
	for i in range(20):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(20.0, 88.0)
		var tx: float = cos(angle) * dist
		var tz: float = sin(angle) * dist
		var ty: float = get_height_at(tx, tz)
		
		if ty > 0.5:
			var tree: Node3D = ProceduralModelBuilder.build_alien_tree(rng)
			tree.position = Vector3(tx, ty, tz)
			tree.rotation.y = rng.randf_range(0.0, TAU)
			props_root.add_child(tree)
			
	# 5. Светящиеся инопланетные кристаллы (24 штуки)
	for i in range(24):
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(12.0, 88.0)
		var cx: float = cos(angle) * dist
		var cz: float = sin(angle) * dist
		var cy: float = get_height_at(cx, cz)
		
		if cy > 0.0:
			var crystal: Node3D = _create_crystal_cluster(i % 2 == 0)
			crystal.position = Vector3(cx, cy, cz)
			crystal.rotation.y = rng.randf_range(0.0, TAU)
			props_root.add_child(crystal)
			
	# 6. Гравитационные гейзеры (Jump Pads — 4 штуки по сторонам света)
	var pad_coords: Array[Vector2] = [
		Vector2(48.0, 0.0),
		Vector2(-48.0, 0.0),
		Vector2(0.0, 48.0),
		Vector2(0.0, -48.0)
	]
	for coord in pad_coords:
		var jy: float = get_height_at(coord.x, coord.y)
		var pad: Node3D = jump_pad_scene.instantiate() as Node3D
		pad.position = Vector3(coord.x, jy, coord.y)
		props_root.add_child(pad)
		
	# 7. Посадочная капсула Drop Pod у точки спавна игрока
	var pod_x: float = 4.2
	var pod_z: float = -3.5
	var pod_y: float = get_height_at(pod_x, pod_z)
	var drop_pod: Node3D = ProceduralModelBuilder.build_drop_pod()
	drop_pod.position = Vector3(pod_x, pod_y, pod_z)
	drop_pod.rotation_degrees = Vector3(8.0, -25.0, -6.0)
	props_root.add_child(drop_pod)
	
	# 8. Море облаков внизу под островом (y = -16.0)
	props_root.add_child(_create_cloud_sea())
	
	# 9. Далёкие парящие острова на горизонте
	props_root.add_child(_create_distant_islands())
	
	# 10. Атмосферные светящиеся споры в воздухе
	props_root.add_child(_create_ambient_particles())


func _create_ruined_column(rng: RandomNumberGenerator) -> StaticBody3D:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 7
	
	# Ступенчатая база
	var base1: MeshInstance3D = MeshInstance3D.new()
	var b1: BoxMesh = BoxMesh.new()
	b1.size = Vector3(2.4, 0.4, 2.4)
	base1.mesh = b1
	base1.position = Vector3(0, 0.2, 0)
	base1.set_surface_override_material(0, mat_rock)
	sb.add_child(base1)
	
	var base2: MeshInstance3D = MeshInstance3D.new()
	var b2: BoxMesh = BoxMesh.new()
	b2.size = Vector3(1.8, 0.35, 1.8)
	base2.mesh = b2
	base2.position = Vector3(0, 0.55, 0)
	base2.set_surface_override_material(0, mat_rock)
	sb.add_child(base2)
	
	# Канелированный ствол колонны (высота 4.2..7.0м)
	var col_h: float = rng.randf_range(4.2, 7.0)
	var col: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = 0.65
	cm.bottom_radius = 0.75
	cm.height = col_h
	cm.radial_segments = 12
	col.mesh = cm
	col.position = Vector3(0, 0.7 + col_h * 0.5, 0)
	col.set_surface_override_material(0, mat_rock)
	sb.add_child(col)
	
	# Капитель или скол с обломком на земле
	if col_h > 5.6:
		var cap: MeshInstance3D = MeshInstance3D.new()
		var c_mesh: BoxMesh = BoxMesh.new()
		c_mesh.size = Vector3(1.7, 0.5, 1.7)
		cap.mesh = c_mesh
		cap.position = Vector3(0, 0.7 + col_h + 0.25, 0)
		cap.set_surface_override_material(0, mat_rock)
		sb.add_child(cap)
	else:
		# Обломок колонны лежит рядом на земле
		var broken: MeshInstance3D = MeshInstance3D.new()
		var b_cyl: CylinderMesh = CylinderMesh.new()
		b_cyl.top_radius = 0.65
		b_cyl.bottom_radius = 0.65
		b_cyl.height = 2.2
		broken.mesh = b_cyl
		broken.position = Vector3(1.3, 0.65, 0.7)
		broken.rotation.z = deg_to_rad(85.0)
		broken.set_surface_override_material(0, mat_rock)
		sb.add_child(broken)
		
	# Светящаяся руническая вставка
	var rune: MeshInstance3D = MeshInstance3D.new()
	var r_mesh: BoxMesh = BoxMesh.new()
	r_mesh.size = Vector3(0.12, 1.8, 1.4)
	rune.mesh = r_mesh
	rune.position = Vector3(0, 2.2, 0)
	rune.set_surface_override_material(0, mat_crystal_cyan if rng.randf() > 0.5 else mat_crystal_amber)
	sb.add_child(rune)
	
	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var cyl_shape: CylinderShape3D = CylinderShape3D.new()
	cyl_shape.radius = 0.95
	cyl_shape.height = col_h + 1.2
	col_shape.position = Vector3(0, (col_h + 1.2) * 0.5, 0)
	col_shape.shape = cyl_shape
	sb.add_child(col_shape)
	
	return sb


func _create_stone_arch() -> StaticBody3D:
	var sb: StaticBody3D = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 7
	
	# Левая колонна
	var col1: MeshInstance3D = MeshInstance3D.new()
	var cm: CylinderMesh = CylinderMesh.new()
	cm.top_radius = 1.2
	cm.bottom_radius = 1.5
	cm.height = 7.0
	cm.radial_segments = 10
	col1.mesh = cm
	col1.position = Vector3(-3.0, 3.5, 0)
	col1.set_surface_override_material(0, mat_rock)
	sb.add_child(col1)
	
	# Правая колонна
	var col2: MeshInstance3D = MeshInstance3D.new()
	col2.mesh = cm
	col2.position = Vector3(3.0, 3.5, 0)
	col2.set_surface_override_material(0, mat_rock)
	sb.add_child(col2)
	
	# Перекладина арки
	var lintel: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = Vector3(8.5, 1.4, 2.8)
	lintel.mesh = bm
	lintel.position = Vector3(0, 7.2, 0)
	lintel.set_surface_override_material(0, mat_rock)
	sb.add_child(lintel)
	
	# Коллизия
	var cs: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(8.5, 8.0, 3.0)
	cs.position = Vector3(0, 4.0, 0)
	cs.shape = shape
	sb.add_child(cs)
	
	return sb


func _create_crystal_cluster(is_cyan: bool) -> Node3D:
	var root: Node3D = Node3D.new()
	var mat: StandardMaterial3D = mat_crystal_cyan if is_cyan else mat_crystal_amber
	var col: Color = Color(0.2, 0.9, 1.0) if is_cyan else Color(1.0, 0.6, 0.15)
	
	# 3 парящих кристалла разной высоты
	for i in range(3):
		var c_mesh: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius = 0.05
		cm.bottom_radius = 0.35
		cm.height = 1.6 + i * 0.4
		cm.radial_segments = 6
		c_mesh.mesh = cm
		c_mesh.set_surface_override_material(0, mat)
		c_mesh.position = Vector3(sin(i * 2.1) * 0.6, cm.height * 0.5, cos(i * 2.1) * 0.6)
		c_mesh.rotation.z = deg_to_rad(sin(i * 1.5) * 15.0)
		root.add_child(c_mesh)
		
	# Локальное мягкое свечение
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = col
	light.light_energy = 1.8
	light.omni_range = 6.5
	light.position = Vector3(0, 1.2, 0)
	root.add_child(light)
	
	return root


func _create_cloud_sea() -> Node3D:
	var cloud_root: Node3D = Node3D.new()
	cloud_root.name = "CloudSea"
	
	var plane_inst: MeshInstance3D = MeshInstance3D.new()
	var pm: PlaneMesh = PlaneMesh.new()
	pm.size = Vector2(1600.0, 1600.0)
	pm.subdivide_width = 4
	pm.subdivide_depth = 4
	plane_inst.mesh = pm
	plane_inst.position = Vector3(0, -16.0, 0)
	
	var mat_cloud: StandardMaterial3D = StandardMaterial3D.new()
	mat_cloud.albedo_color = Color(0.32, 0.28, 0.45, 0.88)
	mat_cloud.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_cloud.roughness = 0.95
	mat_cloud.emission_enabled = true
	mat_cloud.emission = Color(0.18, 0.14, 0.30)
	mat_cloud.emission_energy_multiplier = 0.8
	plane_inst.set_surface_override_material(0, mat_cloud)
	
	cloud_root.add_child(plane_inst)
	return cloud_root


func _create_distant_islands() -> Node3D:
	var islands_root: Node3D = Node3D.new()
	islands_root.name = "DistantIslands"
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 999
	
	for i in range(7):
		var angle: float = (i / 7.0) * TAU + rng.randf_range(-0.15, 0.15)
		var dist: float = rng.randf_range(240.0, 350.0)
		var ix: float = cos(angle) * dist
		var iz: float = sin(angle) * dist
		var iy: float = rng.randf_range(10.0, 35.0)
		
		var island: Node3D = Node3D.new()
		island.position = Vector3(ix, iy, iz)
		
		# Верхняя плоская скала
		var top_m: MeshInstance3D = MeshInstance3D.new()
		var cyl: CylinderMesh = CylinderMesh.new()
		var r_top: float = rng.randf_range(16.0, 28.0)
		cyl.top_radius = r_top
		cyl.bottom_radius = r_top * 0.75
		cyl.height = 5.0
		cyl.radial_segments = 8
		top_m.mesh = cyl
		top_m.set_surface_override_material(0, mat_rock)
		island.add_child(top_m)
		
		# Нижний конический откос острова
		var btm_m: MeshInstance3D = MeshInstance3D.new()
		var cone: CylinderMesh = CylinderMesh.new()
		cone.top_radius = r_top * 0.75
		cone.bottom_radius = 2.0
		cone.height = 14.0
		cone.radial_segments = 8
		btm_m.mesh = cone
		btm_m.position = Vector3(0, -9.5, 0)
		btm_m.set_surface_override_material(0, mat_rock)
		island.add_child(btm_m)
		
		# Кристаллический шпиль на острове
		var spire: MeshInstance3D = MeshInstance3D.new()
		var sp_cone: CylinderMesh = CylinderMesh.new()
		sp_cone.top_radius = 0.2
		sp_cone.bottom_radius = 2.2
		sp_cone.height = 12.0
		sp_cone.radial_segments = 6
		spire.mesh = sp_cone
		spire.position = Vector3(0, 8.5, 0)
		spire.set_surface_override_material(0, mat_crystal_cyan if i % 2 == 0 else mat_crystal_amber)
		island.add_child(spire)
		
		islands_root.add_child(island)
		
	return islands_root


func _create_ambient_particles() -> CPUParticles3D:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.name = "AmbientSpores"
	p.amount = 80
	p.lifetime = 8.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(85.0, 14.0, 85.0)
	p.position = Vector3(0, 8.0, 0)
	p.direction = Vector3(0.2, 0.4, 0.1)
	p.spread = 45.0
	p.gravity = Vector3(0, 0.05, 0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.4
	
	var mat_spore: StandardMaterial3D = StandardMaterial3D.new()
	mat_spore.albedo_color = Color(0.35, 0.85, 1.0, 0.8)
	mat_spore.emission_enabled = true
	mat_spore.emission = Color(0.3, 0.8, 1.0)
	mat_spore.emission_energy_multiplier = 3.0
	mat_spore.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_spore.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 4
	sphere.rings = 2
	sphere.material = mat_spore
	p.mesh = sphere
	
	return p


## Выравнивание ключевых объектов сцены (Игрок, Телепорт, Сундуки) по высоте рельефа
func _align_stage_entities() -> void:
	var parent_node: Node = get_parent()
	if not parent_node:
		return
		
	# Ждем 1 кадр, чтобы вся сцена загрузилась
	call_deferred("_do_align_entities")


func _do_align_entities() -> void:
	var p: Node = get_parent()
	if not p:
		return
		
	for child in p.get_children():
		if child == self:
			continue
		if child is Node3D:
			var n3d: Node3D = child as Node3D
			var gx: float = n3d.position.x
			var gz: float = n3d.position.z
			var hy: float = get_height_at(gx, gz)
			
			if n3d.name.begins_with("Player"):
				n3d.position.y = hy + 1.2
			elif n3d.name.begins_with("Teleporter"):
				n3d.position.y = hy
			elif n3d.name.begins_with("Chest"):
				n3d.position.y = hy
			elif n3d.name.begins_with("InitialBeetle"):
				n3d.position.y = hy + 0.5
			elif n3d.name.begins_with("InitialWisp"):
				n3d.position.y = hy + 4.5
