class_name MainMenu
extends Control
## Главное меню игры VOID THE MATTER (1920x1080).
## Sci-Fi интерфейс с 3D-диорамой десантника в SubViewport,
## плавной кинематикой камеры, стеклянными модальными окнами (Glassmorphism)
## и процедурными звуковыми эффектами.

# Основные кнопки интерфейса
@onready var left_ui: Control = $LeftUI
@onready var buttons_vbox: VBoxContainer = $LeftUI/Margin/VBox/ButtonsVBox
@onready var play_button: Button = $LeftUI/Margin/VBox/ButtonsVBox/PlayButton
@onready var settings_button: Button = $LeftUI/Margin/VBox/ButtonsVBox/SettingsButton
@onready var about_button: Button = $LeftUI/Margin/VBox/ButtonsVBox/AboutButton
@onready var quit_button: Button = $LeftUI/Margin/VBox/ButtonsVBox/QuitButton

# 3D Диорама и Камера
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var camera_3d: Camera3D = $SubViewportContainer/SubViewport/Camera3D
@onready var diorama_root: Node3D = $SubViewportContainer/SubViewport/DioramaRoot
@onready var modal_backdrop: ColorRect = $ModalBackdrop

var _commando_model: Node3D
var _head_node: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _weapon_r: Node3D
var _weapon_l: Node3D
var _jetpack_light: OmniLight3D
var _visor_material: StandardMaterial3D
var _diorama_time: float = 0.0
var _cam_base_pos: Vector3 = Vector3(0.85, 1.45, 3.75)
var _cam_base_rot_y: float = deg_to_rad(-14.5)

# Модальное окно ЛОББИ
@onready var lobby_modal: PanelContainer = $LobbyModal
@onready var close_lobby_btn: Button = $LobbyModal/Margin/VBox/LobbyHeader/CloseLobbyBtn
@onready var selection_view: VBoxContainer = $LobbyModal/Margin/VBox/SelectionView
@onready var room_view: VBoxContainer = $LobbyModal/Margin/VBox/RoomView

@onready var create_public_btn: Button = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/CreateCard/VBox/CreatePublicBtn
@onready var create_private_btn: Button = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/CreateCard/VBox/CreatePrivateBtn
@onready var code_input: LineEdit = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/JoinCard/VBox/CodeHBox/CodeInput
@onready var join_code_btn: Button = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/JoinCard/VBox/CodeHBox/JoinCodeBtn
@onready var lobby_list_vbox: VBoxContainer = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/JoinCard/VBox/PublicScroll/LobbyListVBox
@onready var refresh_list_btn: Button = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/JoinCard/VBox/ListActions/RefreshListBtn
@onready var join_selected_btn: Button = $LobbyModal/Margin/VBox/SelectionView/SplitGrid/JoinCard/VBox/ListActions/JoinSelectedBtn

@onready var room_name_label: Label = $LobbyModal/Margin/VBox/RoomView/RoomInfoCard/HBox/VBox/RoomNameLabel
@onready var copy_code_btn: Button = $LobbyModal/Margin/VBox/RoomView/RoomInfoCard/HBox/CopyCodeBtn
@onready var leave_room_btn: Button = $LobbyModal/Margin/VBox/RoomView/RoomActions/LeaveRoomBtn
@onready var start_drop_btn: Button = $LobbyModal/Margin/VBox/RoomView/RoomActions/StartDropBtn

var _current_lobby_code: String = "VTM-84K"
var _selected_public_index: int = 0
var _public_lobbies_data: Array[Dictionary] = []

# Модальное окно НАСТРОЕК
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var close_settings_btn: Button = $SettingsModal/Margin/VBox/SettingsHeader/CloseSettingsBtn
@onready var master_slider: HSlider = $SettingsModal/Margin/VBox/AudioCard/VBox/MasterBox/MasterSlider
@onready var master_val_label: Label = $SettingsModal/Margin/VBox/AudioCard/VBox/MasterBox/MasterVal
@onready var music_slider: HSlider = $SettingsModal/Margin/VBox/AudioCard/VBox/MusicBox/MusicSlider
@onready var music_val_label: Label = $SettingsModal/Margin/VBox/AudioCard/VBox/MusicBox/MusicVal
@onready var sfx_slider: HSlider = $SettingsModal/Margin/VBox/AudioCard/VBox/SfxBox/SfxSlider
@onready var sfx_val_label: Label = $SettingsModal/Margin/VBox/AudioCard/VBox/SfxBox/SfxVal
@onready var res_option_btn: OptionButton = $SettingsModal/Margin/VBox/VideoCard/VBox/ResBox/ResOptionBtn
@onready var fullscreen_check: CheckBox = $SettingsModal/Margin/VBox/VideoCard/VBox/FullscreenCheck
@onready var apply_settings_btn: Button = $SettingsModal/Margin/VBox/SettingsActions/ApplySettingsBtn
@onready var back_settings_btn: Button = $SettingsModal/Margin/VBox/SettingsActions/BackSettingsBtn

const SETTINGS_PATH: String = "user://settings.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

# Модальное окно КОДЕКС / ОБ ИГРЕ
@onready var about_modal: PanelContainer = $AboutModal
@onready var close_about_btn: Button = $AboutModal/Margin/VBox/AboutHeader/CloseAboutBtn
@onready var back_about_btn: Button = $AboutModal/Margin/VBox/BackAboutBtn

var _active_modal: Control = null
var _button_initial_positions: Dictionary = {}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	_setup_3d_diorama()
	_setup_ui_signals()
	_setup_button_hover_effects()
	_setup_settings_ui()
	_load_settings()
	_populate_public_lobbies()
	_animate_intro()


# =========================================================================
# 1. TWEEN АНИМАЦИИ (Интро и Модальные окна)
# =========================================================================
func _animate_intro() -> void:
	if not left_ui:
		return
		
	# Плавное появление левой колонки (fade-in + сдвиг по X)
	left_ui.modulate.a = 0.0
	var final_x: float = left_ui.position.x
	left_ui.position.x = final_x - 70.0
	
	var intro_tween: Tween = create_tween().set_parallel(true)
	intro_tween.tween_property(left_ui, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(left_ui, "position:x", final_x, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Каскадное появление кнопок меню
	var menu_buttons: Array[Button] = [play_button, settings_button, about_button, quit_button]
	for i in range(menu_buttons.size()):
		var btn: Button = menu_buttons[i]
		btn.modulate.a = 0.0
		var btn_final_x: float = btn.position.x
		btn.position.x = btn_final_x - 40.0
		
		var btn_tween: Tween = create_tween().set_parallel(true)
		btn_tween.tween_interval(0.15 + i * 0.07)
		btn_tween.chain().tween_property(btn, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		btn_tween.tween_property(btn, "position:x", btn_final_x, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _play_sfx(sound_name: String) -> void:
	var am: Node = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.call("play_sfx", sound_name)


func _setup_button_hover_effects() -> void:
	var interactive_buttons: Array[Button] = [
		play_button, settings_button, about_button, quit_button,
		create_public_btn, create_private_btn, start_drop_btn, apply_settings_btn
	]
	
	for btn in interactive_buttons:
		if not is_instance_valid(btn):
			continue
			
		btn.mouse_entered.connect(func() -> void:
			_play_sfx("ui_hover")
			var tw: Tween = create_tween()
			tw.tween_property(btn, "position:x", 10.0, 0.15).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
		btn.mouse_exited.connect(func() -> void:
			var tw: Tween = create_tween()
			tw.tween_property(btn, "position:x", -10.0, 0.15).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		)
		
		btn.pressed.connect(func() -> void:
			_play_sfx("ui_click")
		)


func _open_modal(modal: Control) -> void:
	if _active_modal and _active_modal != modal:
		_active_modal.visible = false
		
	_active_modal = modal
	modal_backdrop.visible = true
	modal_backdrop.modulate.a = 0.0
	
	modal.visible = true
	modal.modulate.a = 0.0
	modal.pivot_offset = modal.size * 0.5
	modal.scale = Vector2(0.92, 0.92)
	
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(modal_backdrop, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(modal, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(modal, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_modal(modal: Control) -> void:
	if not modal or not modal.visible:
		return
		
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(modal, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(modal, "scale", Vector2(0.94, 0.94), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(modal_backdrop, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD)
	
	tw.chain().tween_callback(func() -> void:
		modal.visible = false
		modal_backdrop.visible = false
		if _active_modal == modal:
			_active_modal = null
	)


# =========================================================================
# 2. 3D ДИОРАМА ПЕРСОНАЖА (Пьедестал, Кристаллы, Подсветка, Камера)
# =========================================================================
func _setup_3d_diorama() -> void:
	if not diorama_root:
		return
		
	# 1. Каменный пьедестал со ступенями и неоновым кольцом
	var mat_pedestal: StandardMaterial3D = StandardMaterial3D.new()
	mat_pedestal.albedo_color = Color(0.12, 0.10, 0.17)
	mat_pedestal.roughness = 0.92
	
	var mat_pedestal_rune: StandardMaterial3D = StandardMaterial3D.new()
	mat_pedestal_rune.albedo_color = Color(0, 0.94, 1.0)
	mat_pedestal_rune.emission_enabled = true
	mat_pedestal_rune.emission = Color(0, 0.94, 1.0)
	mat_pedestal_rune.emission_energy_multiplier = 4.5
	
	var base_step: MeshInstance3D = MeshInstance3D.new()
	var cyl_base: CylinderMesh = CylinderMesh.new()
	cyl_base.top_radius = 2.4
	cyl_base.bottom_radius = 2.65
	cyl_base.height = 0.35
	cyl_base.radial_segments = 16
	base_step.mesh = cyl_base
	base_step.position = Vector3(1.2, 0.17, 0)
	base_step.set_surface_override_material(0, mat_pedestal)
	diorama_root.add_child(base_step)
	
	var top_step: MeshInstance3D = MeshInstance3D.new()
	var cyl_top: CylinderMesh = CylinderMesh.new()
	cyl_top.top_radius = 2.0
	cyl_top.bottom_radius = 2.25
	cyl_top.height = 0.35
	cyl_top.radial_segments = 16
	top_step.mesh = cyl_top
	top_step.position = Vector3(1.2, 0.42, 0)
	top_step.set_surface_override_material(0, mat_pedestal)
	diorama_root.add_child(top_step)
	
	# Неоновое кольцо на пьедестале
	var ring: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 1.72
	torus.outer_radius = 1.84
	ring.mesh = torus
	ring.position = Vector3(1.2, 0.61, 0)
	ring.set_surface_override_material(0, mat_pedestal_rune)
	diorama_root.add_child(ring)
	
	# 2. Светящиеся кристаллы по периметру
	var crystal_mat: StandardMaterial3D = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(1, 0.68, 0.12)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(1, 0.68, 0.12)
	crystal_mat.emission_energy_multiplier = 4.8
	
	for i in range(4):
		var ang: float = i * 1.57 + 0.38
		var c_mesh: MeshInstance3D = MeshInstance3D.new()
		var cm: CylinderMesh = CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.22
		cm.height = 0.85 + (i % 2) * 0.4
		cm.radial_segments = 6
		c_mesh.mesh = cm
		c_mesh.set_surface_override_material(0, crystal_mat)
		c_mesh.position = Vector3(1.2 + cos(ang) * 1.85, 0.6 + cm.height * 0.5, sin(ang) * 1.85)
		c_mesh.rotation.z = deg_to_rad(sin(ang) * 16.0)
		diorama_root.add_child(c_mesh)
		
	# 3. Летающие частицы космической пыли и искр
	var sparks: CPUParticles3D = CPUParticles3D.new()
	sparks.name = "DioramaSparks"
	sparks.amount = 38
	sparks.lifetime = 4.8
	sparks.preprocess = 2.0
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(2.5, 1.4, 2.5)
	sparks.position = Vector3(1.2, 1.6, 0)
	sparks.gravity = Vector3(0, 0.12, 0)
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 45.0
	sparks.initial_velocity_min = 0.08
	sparks.initial_velocity_max = 0.35
	
	var mat_spark: StandardMaterial3D = StandardMaterial3D.new()
	mat_spark.albedo_color = Color(0.1, 0.94, 1.0, 0.95)
	mat_spark.emission_enabled = true
	mat_spark.emission = Color(0.1, 0.94, 1.0)
	mat_spark.emission_energy_multiplier = 4.5
	mat_spark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_spark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var spark_mesh: SphereMesh = SphereMesh.new()
	spark_mesh.radius = 0.03
	spark_mesh.height = 0.06
	spark_mesh.radial_segments = 4
	spark_mesh.rings = 2
	spark_mesh.material = mat_spark
	sparks.mesh = spark_mesh
	diorama_root.add_child(sparks)
	
	# 4. Модель персонажа Commando
	_commando_model = ProceduralModelBuilder.build_commando()
	_commando_model.position = Vector3(1.2, 0.6, 0)
	_commando_model.rotation_degrees = Vector3(0, -32.0, 0)
	diorama_root.add_child(_commando_model)
	
	_find_commando_parts(_commando_model)


func _find_commando_parts(node: Node) -> void:
	if node.name == "Head":
		_head_node = node as Node3D
	elif node.name == "ArmPivotL":
		_arm_l = node as Node3D
	elif node.name == "ArmPivotR":
		_arm_r = node as Node3D
	elif node.name == "WeaponR":
		_weapon_r = node as Node3D
	elif node.name == "WeaponL":
		_weapon_l = node as Node3D
	elif node.name == "JetpackLight":
		_jetpack_light = node as OmniLight3D
	elif node.name == "Visor" and node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.get_surface_override_material_count() > 0:
			var m: Material = mi.get_surface_override_material(0)
			if m is StandardMaterial3D:
				_visor_material = m as StandardMaterial3D
				
	for child in node.get_children():
		_find_commando_parts(child)


func _process(delta: float) -> void:
	_diorama_time += delta
	_animate_commando_idle(delta, _diorama_time)
	_animate_camera_sway(delta, _diorama_time)


## Плавное кинематографическое покачивание камеры (Slow Orbit / Idle Sway)
func _animate_camera_sway(delta: float, time: float) -> void:
	if not is_instance_valid(camera_3d):
		return
		
	var sway_x: float = sin(time * 0.32) * 0.22
	var sway_y: float = cos(time * 0.48) * 0.07
	var sway_yaw: float = sin(time * 0.28) * deg_to_rad(2.4)
	
	camera_3d.position.x = lerpf(camera_3d.position.x, _cam_base_pos.x + sway_x, 3.0 * delta)
	camera_3d.position.y = lerpf(camera_3d.position.y, _cam_base_pos.y + sway_y, 3.0 * delta)
	camera_3d.rotation.y = lerpf(camera_3d.rotation.y, _cam_base_rot_y + sway_yaw, 3.0 * delta)


## Процедурная Idle-анимация десантника
func _animate_commando_idle(delta: float, time: float) -> void:
	if not _commando_model:
		return
		
	# 1. Дыхание груди (микро-подъём)
	var breathe_y: float = sin(time * 2.2) * 0.016
	_commando_model.position.y = 0.6 + breathe_y
	
	# 2. Плечи и руки
	var arm_breathe: float = sin(time * 2.2) * deg_to_rad(3.0)
	if is_instance_valid(_arm_l):
		_arm_l.rotation.x = lerp_angle(_arm_l.rotation.x, arm_breathe, 8.0 * delta)
	if is_instance_valid(_arm_r):
		_arm_r.rotation.x = lerp_angle(_arm_r.rotation.x, -arm_breathe * 0.7, 8.0 * delta)
		
	# 3. Покачивание бластеров
	if is_instance_valid(_weapon_r):
		_weapon_r.rotation.z = deg_to_rad(4.0) + sin(time * 1.8) * deg_to_rad(2.2)
	if is_instance_valid(_weapon_l):
		_weapon_l.rotation.z = deg_to_rad(-4.0) - sin(time * 1.8) * deg_to_rad(2.2)
		
	# 4. Осмотр пространства головой
	if is_instance_valid(_head_node):
		var look_yaw: float = sin(time * 0.65) * deg_to_rad(14.0)
		var look_pitch: float = sin(time * 1.3) * deg_to_rad(4.0)
		_head_node.rotation.y = lerp_angle(_head_node.rotation.y, look_yaw, 4.0 * delta)
		_head_node.rotation.x = lerp_angle(_head_node.rotation.x, look_pitch, 4.0 * delta)
		
	# 5. Пульсация неонового визора
	if _visor_material:
		_visor_material.emission_energy_multiplier = 3.2 + sin(time * 2.8) * 0.8
		
	# 6. Мягкое свечение сопел джетпака
	if is_instance_valid(_jetpack_light):
		_jetpack_light.light_energy = 1.8 + sin(time * 5.5) * 0.5


# =========================================================================
# 3. ОСНОВНЫЕ СИГНАЛЫ UI И НАВИГАЦИЯ
# =========================================================================
func _setup_ui_signals() -> void:
	play_button.pressed.connect(func() -> void:
		_open_lobby_modal()
	)
	
	settings_button.pressed.connect(func() -> void:
		_open_modal(settings_modal)
	)
	
	about_button.pressed.connect(func() -> void:
		_open_modal(about_modal)
	)
	
	quit_button.pressed.connect(func() -> void:
		get_tree().quit()
	)
	
	# Кнопки закрытия модальных окон
	close_lobby_btn.pressed.connect(func() -> void:
		_close_modal(lobby_modal)
	)
	
	close_settings_btn.pressed.connect(func() -> void:
		_close_modal(settings_modal)
	)
	back_settings_btn.pressed.connect(func() -> void:
		_close_modal(settings_modal)
	)
	
	close_about_btn.pressed.connect(func() -> void:
		_close_modal(about_modal)
	)
	back_about_btn.pressed.connect(func() -> void:
		_close_modal(about_modal)
	)
	
	# Клик по фону для закрытия окон
	modal_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _active_modal:
				_close_modal(_active_modal)
	)
	
	# Сигналы лобби
	create_public_btn.pressed.connect(_on_create_public_lobby)
	create_private_btn.pressed.connect(_on_create_private_lobby)
	join_code_btn.pressed.connect(_on_join_by_code)
	refresh_list_btn.pressed.connect(_populate_public_lobbies)
	join_selected_btn.pressed.connect(_on_join_selected_public)
	copy_code_btn.pressed.connect(_on_copy_code)
	leave_room_btn.pressed.connect(_on_leave_room)
	start_drop_btn.pressed.connect(_start_game_drop)


# =========================================================================
# 4. СИСТЕМА ЛОББИ (Публичное / Приватное)
# =========================================================================
func _open_lobby_modal() -> void:
	selection_view.visible = true
	room_view.visible = false
	_open_modal(lobby_modal)


func _generate_random_code() -> String:
	var chars: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code: String = "VTM-"
	for i in range(3):
		var idx: int = randi() % chars.length()
		code += chars[idx]
	return code


func _on_create_public_lobby() -> void:
	var room_num: int = randi_range(100, 999)
	_current_lobby_code = "PUB-#%d" % room_num
	room_name_label.text = "КОМНАТА ОЖИДАНИЯ: ЛОББИ #%d [ОТКРЫТОЕ]" % room_num
	copy_code_btn.visible = false
	selection_view.visible = false
	room_view.visible = true


func _on_create_private_lobby() -> void:
	_current_lobby_code = _generate_random_code()
	room_name_label.text = "КОМНАТА ОЖИДАНИЯ: %s [ПРИВАТНОЕ]" % _current_lobby_code
	copy_code_btn.text = "📋 Скопировать код (%s)" % _current_lobby_code
	copy_code_btn.visible = true
	selection_view.visible = false
	room_view.visible = true


func _on_join_by_code() -> void:
	var code_text: String = code_input.text.strip_edges().to_upper()
	if code_text.length() >= 4:
		_current_lobby_code = code_text
		room_name_label.text = "КОМНАТА ОЖИДАНИЯ: %s [ПРИВАТНОЕ]" % _current_lobby_code
		copy_code_btn.text = "📋 Скопировать код (%s)" % _current_lobby_code
		copy_code_btn.visible = true
		selection_view.visible = false
		room_view.visible = true
	else:
		code_input.placeholder_text = "Код должен быть от 4 символов!"


func _populate_public_lobbies() -> void:
	for child in lobby_list_vbox.get_children():
		child.queue_free()
		
	_public_lobbies_data.clear()
	var templates: Array[Dictionary] = [
		{"name": "Лобби #104 [Открытое]", "players": 1, "max": 4, "ping": randi_range(14, 22)},
		{"name": "Лобби #209 [Быстрая игра]", "players": 2, "max": 4, "ping": randi_range(26, 36)},
		{"name": "Лобби #312 [Мастера Бездны]", "players": 3, "max": 4, "ping": randi_range(38, 52)},
		{"name": "Лобби #480 [Фарм Плато]", "players": 1, "max": 4, "ping": randi_range(18, 28)}
	]
	
	for i in range(templates.size()):
		var data: Dictionary = templates[i]
		_public_lobbies_data.append(data)
		
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 36)
		btn.text = "%s  —  Десантники: %d/%d  —  Пинг: %d мс" % [
			data["name"], data["players"], data["max"], data["ping"]
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var idx: int = i
		btn.pressed.connect(func() -> void:
			_play_sfx("ui_click")
			_selected_public_index = idx
			_highlight_selected_lobby_btn()
		)
		lobby_list_vbox.add_child(btn)
		
	_highlight_selected_lobby_btn()


func _highlight_selected_lobby_btn() -> void:
	var children: Array[Node] = lobby_list_vbox.get_children()
	for i in range(children.size()):
		var btn: Button = children[i] as Button
		if i == _selected_public_index:
			btn.modulate = Color(0, 0.94, 1.0)
		else:
			btn.modulate = Color(0.85, 0.9, 1.0)


func _on_join_selected_public() -> void:
	if _selected_public_index >= 0 and _selected_public_index < _public_lobbies_data.size():
		var data: Dictionary = _public_lobbies_data[_selected_public_index]
		_current_lobby_code = data["name"]
		room_name_label.text = "КОМНАТА ОЖИДАНИЯ: %s" % data["name"]
		copy_code_btn.visible = false
		selection_view.visible = false
		room_view.visible = true


func _on_copy_code() -> void:
	DisplayServer.clipboard_set(_current_lobby_code)
	copy_code_btn.text = "✓ Скопировано в буфер!"
	var timer: SceneTreeTimer = get_tree().create_timer(1.8)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(copy_code_btn):
			copy_code_btn.text = "📋 Скопировать код (%s)" % _current_lobby_code
	)


func _on_leave_room() -> void:
	room_view.visible = false
	selection_view.visible = true


func _start_game_drop() -> void:
	get_tree().change_scene_to_file("res://scenes/world/test_island.tscn")


# =========================================================================
# 5. МЕНЮ НАСТРОЕК (Звук, Музыка, Разрешение экрана, Сохранение)
# =========================================================================
func _setup_settings_ui() -> void:
	res_option_btn.clear()
	for res in RESOLUTIONS:
		res_option_btn.add_item("%dx%d" % [res.x, res.y])
	res_option_btn.selected = 2
	
	master_slider.value_changed.connect(func(val: float) -> void:
		master_val_label.text = "%d%%" % int(val)
		_set_bus_volume(0, val)
	)
	
	music_slider.value_changed.connect(func(val: float) -> void:
		music_val_label.text = "%d%%" % int(val)
		_set_bus_volume(1, val)
	)
	
	sfx_slider.value_changed.connect(func(val: float) -> void:
		sfx_val_label.text = "%d%%" % int(val)
		_set_bus_volume(2, val)
	)
	
	apply_settings_btn.pressed.connect(_save_settings)


func _set_bus_volume(bus_idx: int, percent: float) -> void:
	if bus_idx >= AudioServer.bus_count:
		return
	var db: float
	if percent <= 0.0:
		db = -80.0
	else:
		db = linear_to_db(percent / 100.0)
	AudioServer.set_bus_volume_db(bus_idx, db)


func _save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master", master_slider.value)
	cfg.set_value("audio", "music", music_slider.value)
	cfg.set_value("audio", "sfx", sfx_slider.value)
	
	var res_idx: int = res_option_btn.selected
	if res_idx >= 0 and res_idx < RESOLUTIONS.size():
		var res: Vector2i = RESOLUTIONS[res_idx]
		cfg.set_value("video", "resolution_x", res.x)
		cfg.set_value("video", "resolution_y", res.y)
		DisplayServer.window_set_size(res)
		
	var is_fs: bool = fullscreen_check.button_pressed
	cfg.set_value("video", "fullscreen", is_fs)
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	cfg.save(SETTINGS_PATH)
	
	apply_settings_btn.text = "✓ НАСТРОЙКИ СОХРАНЕНЫ!"
	var t: SceneTreeTimer = get_tree().create_timer(1.5)
	t.timeout.connect(func() -> void:
		if is_instance_valid(apply_settings_btn):
			apply_settings_btn.text = "💾  ПРИМЕНИТЬ И СОХРАНИТЬ"
	)


func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(SETTINGS_PATH)
	if err != OK:
		_set_bus_volume(0, 100.0)
		_set_bus_volume(1, 85.0)
		_set_bus_volume(2, 100.0)
		return
		
	var master: float = cfg.get_value("audio", "master", 100.0)
	var music: float = cfg.get_value("audio", "music", 85.0)
	var sfx: float = cfg.get_value("audio", "sfx", 100.0)
	
	master_slider.value = master
	master_val_label.text = "%d%%" % int(master)
	_set_bus_volume(0, master)
	
	music_slider.value = music
	music_val_label.text = "%d%%" % int(music)
	_set_bus_volume(1, music)
	
	sfx_slider.value = sfx
	sfx_val_label.text = "%d%%" % int(sfx)
	_set_bus_volume(2, sfx)
	
	var rx: int = cfg.get_value("video", "resolution_x", 1920)
	var ry: int = cfg.get_value("video", "resolution_y", 1080)
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i].x == rx and RESOLUTIONS[i].y == ry:
			res_option_btn.selected = i
			break
			
	var is_fs: bool = cfg.get_value("video", "fullscreen", false)
	fullscreen_check.button_pressed = is_fs
	if is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(rx, ry))
