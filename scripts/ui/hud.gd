class_name HUD
extends CanvasLayer
## Интерфейс в аутентичном стиле Risk of Rain 2.
## Здоровье, Золото ($), Уровень/XP, Прицел, Шкала сложности,
## Нижняя центральная панель инвентаря (56x56 px карточки с векторными иконками и стаками),
## Всплывающий баннер подбора предметов (Pickup Notification Banner на 3.5 сек),
## Контекстные подсказки и полоса Босса. Никаких плашек подсказок управления внизу!

@export var player: PlayerController
@export var difficulty_manager: DifficultyManager
@export var teleporter: Teleporter

# Здоровье и Опыт
@onready var health_bar: ProgressBar = $BottomLeft/VBox/HealthBar
@onready var health_label: Label = $BottomLeft/VBox/HealthBar/HealthLabel
@onready var xp_bar: ProgressBar = $BottomLeft/VBox/XPBar
@onready var level_label: Label = $BottomLeft/VBox/HBox/LevelLabel
@onready var gold_label: Label = $BottomLeft/VBox/HBox/GoldLabel

# Шкала Сложности (RoR Timer)
@onready var timer_label: Label = $TopRight/VBox/TimerLabel
@onready var difficulty_label: Label = $TopRight/VBox/DifficultyLabel
@onready var difficulty_bar: ProgressBar = $TopRight/VBox/DifficultyBar

# Контекстная подсказка взаимодействия
@onready var interact_prompt: Label = get_node_or_null("InteractPrompt")

# Нижний Инвентарь (InventoryBar)
@onready var inventory_bar: PanelContainer = get_node_or_null("InventoryBar")
@onready var inventory_hbox: HBoxContainer = get_node_or_null("InventoryBar/Scroll/InventoryHBox")

# Всплывающий баннер подбора (Pickup Notification Banner)
@onready var pickup_banner: PanelContainer = get_node_or_null("PickupBanner")
@onready var banner_icon_rect: ColorRect = get_node_or_null("PickupBanner/HBox/BannerIcon")
@onready var banner_title: Label = get_node_or_null("PickupBanner/HBox/VBox/ItemTitle")
@onready var banner_desc: Label = get_node_or_null("PickupBanner/HBox/VBox/ItemDesc")

# Босс и Телепорт
@onready var boss_container: VBoxContainer = $TopCenter/VBox/BossContainer
@onready var boss_bar: ProgressBar = $TopCenter/VBox/BossContainer/BossBar
@onready var boss_title: Label = $TopCenter/VBox/BossContainer/BossTitle
@onready var teleporter_label: Label = $TopCenter/VBox/TeleporterChargeLabel

# Меню паузы
@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_btn: Button = $PausePanel/VBox/ResumeButton
@onready var menu_btn: Button = $PausePanel/VBox/MenuButton
@onready var quit_btn: Button = $PausePanel/VBox/QuitButton

var _banner_tween: Tween
var _banner_icon: ItemIcon


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if boss_container:
		boss_container.visible = false
	if teleporter_label:
		teleporter_label.visible = false
	if pause_panel:
		pause_panel.visible = false
	if interact_prompt:
		interact_prompt.visible = false
	if pickup_banner:
		pickup_banner.visible = false
		pickup_banner.modulate = Color(1, 1, 1, 0)
		
	# Подготавливаем иконку для баннера
	if banner_icon_rect:
		banner_icon_rect.color = Color(0, 0, 0, 0) # Прозрачный фон
		_banner_icon = ItemIcon.new()
		_banner_icon.custom_minimum_size = Vector2(44, 44)
		_banner_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		banner_icon_rect.add_child(_banner_icon)
		
	if resume_btn:
		resume_btn.pressed.connect(toggle_pause)
	if menu_btn:
		menu_btn.pressed.connect(func() -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)
	if quit_btn:
		quit_btn.pressed.connect(func() -> void: get_tree().quit())
		
	if player:
		_bind_player(player)
	if difficulty_manager:
		difficulty_manager.time_updated.connect(_on_time_updated)
	if teleporter:
		_bind_teleporter(teleporter)
		
	_set_mouse_filter_ignore(self)


func _set_mouse_filter_ignore(node: Node) -> void:
	if node is Control and not (node is Button or node == pause_panel or node.is_ancestor_of(pause_panel)):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)



func _process(_delta: float) -> void:
	_update_interact_prompt()


func _update_interact_prompt() -> void:
	if not interact_prompt:
		return
		
	if not is_instance_valid(player) or not player.current_interactable:
		interact_prompt.visible = false
		return
		
	var obj: Node3D = player.current_interactable
	if obj is Chest:
		var chest: Chest = obj as Chest
		interact_prompt.visible = true
		if chest.is_opened:
			interact_prompt.text = "СУНДУК ОТКРЫТ"
			interact_prompt.modulate = Color(0.6, 0.6, 0.6)
		else:
			interact_prompt.text = "[E] Открыть сундук ($%d)" % chest.cost
			interact_prompt.modulate = Color(1.0, 0.85, 0.2) if player.gold >= chest.cost else Color(1.0, 0.3, 0.3)
	elif obj is Teleporter:
		var tp: Teleporter = obj as Teleporter
		interact_prompt.visible = true
		match tp.state:
			Teleporter.TeleporterState.IDLE:
				interact_prompt.text = "[E] Активировать Телепорт (Призвать Босса)"
				interact_prompt.modulate = Color(1.0, 0.7, 0.2)
			Teleporter.TeleporterState.CHARGING:
				interact_prompt.text = "ЗАРЯДКА: %d%%" % int(tp.charge_progress)
				interact_prompt.modulate = Color(0.9, 0.9, 0.9)
			Teleporter.TeleporterState.CHARGED:
				interact_prompt.text = "[E] Активировать Телепорт (Завершить этап)"
				interact_prompt.modulate = Color(0.2, 1.0, 0.4)
			_:
				interact_prompt.visible = false
	else:
		interact_prompt.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	if pause_panel:
		pause_panel.visible = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _bind_player(p: PlayerController) -> void:
	player = p
	player.health_changed.connect(_on_health_changed)
	player.gold_changed.connect(_on_gold_changed)
	player.xp_changed.connect(_on_xp_changed)
	if player.has_signal("item_collected_banner"):
		player.item_collected_banner.connect(show_pickup_banner)
	if player.inventory:
		player.inventory.item_collected.connect(_on_item_collected)


func _bind_teleporter(tp: Teleporter) -> void:
	teleporter = tp
	teleporter.boss_spawned.connect(_on_boss_spawned)
	teleporter.charge_updated.connect(func(percent: float) -> void:
		teleporter_label.visible = true
		teleporter_label.text = "ЗАРЯДКА ТЕЛЕПОРТА: %d%%" % int(percent)
	)
	teleporter.teleporter_charged.connect(func() -> void:
		teleporter_label.text = "ТЕЛЕПОРТ ГОТОВ! [E]"
		teleporter_label.modulate = Color(0.2, 1.0, 0.4)
	)


func _on_health_changed(current: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current
	if health_label:
		health_label.text = "%d / %d" % [int(current), int(max_hp)]


func _on_gold_changed(amount: int) -> void:
	if gold_label:
		gold_label.text = "$ %d" % amount


func _on_xp_changed(current: int, needed: int, lvl: int) -> void:
	if xp_bar:
		xp_bar.max_value = needed
		xp_bar.value = current
	if level_label:
		level_label.text = "УР. %d" % lvl


func _on_time_updated(time_str: String, diff_name: String, ratio: float) -> void:
	if timer_label:
		timer_label.text = time_str
	if difficulty_label:
		difficulty_label.text = diff_name
	if difficulty_bar:
		difficulty_bar.value = ratio * 100.0


## Отображение карточки предмета в нижней панели инвентаря
func _on_item_collected(item: ItemData, total: int) -> void:
	if not inventory_hbox:
		return
		
	var node_name: String = "item_" + str(item.id)
	var existing: PanelContainer = inventory_hbox.get_node_or_null(node_name) as PanelContainer
	
	if existing:
		# Обновляем счётчик стаков
		var badge: Label = existing.get_node_or_null("Badge") as Label
		if badge:
			badge.text = "x%d" % total
			badge.visible = total > 1
		existing.tooltip_text = "%s (x%d)\n%s" % [item.item_name, total, item.description]
		
		# Мягкий визуальный импульс при добавлении стака
		var pulse: Tween = create_tween()
		pulse.tween_property(existing, "scale", Vector2(1.18, 1.18), 0.12).set_trans(Tween.TRANS_BACK)
		pulse.tween_property(existing, "scale", Vector2.ONE, 0.15)
	else:
		# Создаём новую карточку (>=58x58 px)
		var card: PanelContainer = PanelContainer.new()
		card.name = node_name
		card.custom_minimum_size = Vector2(58, 58)
		card.pivot_offset = Vector2(29, 29)
		card.tooltip_text = "%s (x%d)\n%s" % [item.item_name, total, item.description]
		
		# Стиль рамки и фона по редкости предмета
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.07, 0.12, 0.88)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		
		var tier_color: Color = Color.WHITE
		match item.tier:
			ItemData.ItemTier.WHITE:
				tier_color = Color(0.75, 0.9, 1.0)
			ItemData.ItemTier.GREEN:
				tier_color = Color(0.2, 0.95, 0.45)
			ItemData.ItemTier.RED:
				tier_color = Color(1.0, 0.3, 0.3)
			ItemData.ItemTier.BOSS:
				tier_color = Color(1.0, 0.85, 0.2)
				
		style.border_color = tier_color
		card.add_theme_stylebox_override("panel", style)
		
		# Контейнер для центрирования иконки
		var icon_container: CenterContainer = CenterContainer.new()
		icon_container.custom_minimum_size = Vector2(58, 58)
		icon_container.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Процедурная векторная иконка
		var icon_draw: ItemIcon = ItemIcon.new()
		icon_draw.custom_minimum_size = Vector2(46, 46)
		icon_draw.setup(item.id, item.tier)
		icon_container.add_child(icon_draw)
		card.add_child(icon_container)
		
		# Бейдж счётчика стаков в нижнем правом углу
		var badge: Label = Label.new()
		badge.name = "Badge"
		badge.text = "x%d" % total
		badge.visible = total > 1
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
		badge.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.08))
		badge.add_theme_constant_override("outline_size", 4)
		badge.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)
		
		inventory_hbox.add_child(card)
		
		# Анимация появления карточки
		card.scale = Vector2(0.2, 0.2)
		var spawn_tween: Tween = create_tween()
		spawn_tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)


## Показ всплывающего баннера подбора на 3.5 секунды
func show_pickup_banner(item: ItemData, total: int) -> void:
	if not pickup_banner:
		return
		
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
		
	var tier_name: String = "ОБЫЧНЫЙ"
	var tier_color: Color = Color(0.75, 0.9, 1.0)
	match item.tier:
		ItemData.ItemTier.WHITE:
			tier_name = "ОБЫЧНЫЙ"
			tier_color = Color(0.75, 0.9, 1.0)
		ItemData.ItemTier.GREEN:
			tier_name = "РЕДКИЙ"
			tier_color = Color(0.2, 0.95, 0.45)
		ItemData.ItemTier.RED:
			tier_name = "ЛЕГЕНДАРНЫЙ"
			tier_color = Color(1.0, 0.3, 0.3)
		ItemData.ItemTier.BOSS:
			tier_name = "БОСС"
			tier_color = Color(1.0, 0.85, 0.2)
			
	if banner_title:
		banner_title.text = "«%s» — %s (x%d)" % [item.item_name.to_upper(), tier_name, total]
		banner_title.add_theme_color_override("font_color", tier_color)
		
	if banner_desc:
		banner_desc.text = item.description
		
	if _banner_icon:
		_banner_icon.setup(item.id, item.tier)
		
	pickup_banner.visible = true
	pickup_banner.modulate = Color(1, 1, 1, 0.0)
	pickup_banner.position.y = get_viewport().get_visible_rect().size.y - 145.0
	
	_banner_tween = create_tween()
	# Плавное появление вверх
	_banner_tween.tween_property(pickup_banner, "modulate:a", 1.0, 0.25)
	_banner_tween.parallel().tween_property(pickup_banner, "position:y", get_viewport().get_visible_rect().size.y - 170.0, 0.25).set_trans(Tween.TRANS_QUAD)
	# Показ в течение 3.5 секунд
	_banner_tween.tween_interval(3.5)
	# Плавное угасание
	_banner_tween.tween_property(pickup_banner, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(func() -> void:
		pickup_banner.visible = false
	)


func _on_boss_spawned(boss: StoneTitanBoss) -> void:
	if not boss_container:
		return
	boss_container.visible = true
	boss_bar.max_value = boss.max_health
	boss_bar.value = boss.current_health
	boss.boss_health_updated.connect(func(cur: float, max_hp: float) -> void:
		boss_bar.max_value = max_hp
		boss_bar.value = cur
	)
	boss.titan_slain.connect(func() -> void:
		boss_container.visible = false
	)
