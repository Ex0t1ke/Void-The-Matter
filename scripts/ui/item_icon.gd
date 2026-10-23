class_name ItemIcon
extends Control
## Процедурная отрисовка уникальных векторных иконок для предметов (56x56 или любого размера).

@export var item_id: StringName = &""
@export var tier: ItemData.ItemTier = ItemData.ItemTier.WHITE
@export var base_color: Color = Color(0.85, 0.95, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(id: StringName, item_tier: ItemData.ItemTier) -> void:
	item_id = id
	tier = item_tier
	match tier:
		ItemData.ItemTier.WHITE:
			base_color = Color(0.8, 0.95, 1.0)
		ItemData.ItemTier.GREEN:
			base_color = Color(0.25, 0.95, 0.45)
		ItemData.ItemTier.RED:
			base_color = Color(1.0, 0.3, 0.3)
		ItemData.ItemTier.BOSS:
			base_color = Color(1.0, 0.85, 0.2)
	queue_redraw()


func _draw() -> void:
	var s: Vector2 = size
	var center: Vector2 = s * 0.5
	var r: float = minf(s.x, s.y) * 0.42
	
	# Мягкое фоновое свечение в центре иконки
	draw_circle(center, r * 0.75, Color(base_color.r, base_color.g, base_color.b, 0.18))
	
	match str(item_id):
		"soldiers_syringe":
			_draw_syringe(center, r)
		"tougher_times":
			_draw_teddy_shield(center, r)
		"hopoo_feather":
			_draw_feather(center, r)
		"ukulele":
			_draw_ukulele(center, r)
		"gasoline":
			_draw_gasoline(center, r)
		_:
			_draw_generic_crystal(center, r)


func _draw_syringe(c: Vector2, r: float) -> void:
	# Шприц солдата: колба под 45 градусов, игла и светящийся реагент
	var p1: Vector2 = c + Vector2(-r * 0.5, r * 0.5)
	var p2: Vector2 = c + Vector2(r * 0.4, -r * 0.4)
	var needle_tip: Vector2 = c + Vector2(r * 0.8, -r * 0.8)
	var plunger: Vector2 = c + Vector2(-r * 0.85, r * 0.85)
	
	# Корпус шприца
	draw_line(p1, p2, base_color, 7.0, true)
	# Внутренняя светящаяся жидкость
	draw_line(p1 + Vector2(2, -2), p2 - Vector2(2, -2), Color(0.2, 1.0, 0.8), 3.0, true)
	# Игла
	draw_line(p2, needle_tip, Color(1, 1, 1, 0.95), 2.0, true)
	# Поршень
	draw_line(p1, plunger, base_color.darkened(0.2), 3.0, true)
	draw_circle(plunger, 3.5, base_color)


func _draw_teddy_shield(c: Vector2, r: float) -> void:
	# Плюшевый мишка / защитный щит
	# Голова мишки
	draw_circle(c + Vector2(0, 2), r * 0.55, base_color)
	# Ушки
	draw_circle(c + Vector2(-r * 0.45, -r * 0.35), r * 0.25, base_color)
	draw_circle(c + Vector2(r * 0.45, -r * 0.35), r * 0.25, base_color)
	# Глазки-пуговицы крестиком
	var eye_c: Color = Color(0.08, 0.08, 0.12)
	draw_circle(c + Vector2(-r * 0.2, 0), 2.2, eye_c)
	draw_circle(c + Vector2(r * 0.2, 0), 2.2, eye_c)
	# Мордочка
	draw_circle(c + Vector2(0, r * 0.2), 3.0, eye_c)


func _draw_feather(c: Vector2, r: float) -> void:
	# Перо Hopoo: изогнутый стержень и бородки
	var pts: PackedVector2Array = [
		c + Vector2(-r * 0.6, r * 0.7),
		c + Vector2(-r * 0.2, r * 0.2),
		c + Vector2(r * 0.2, -r * 0.3),
		c + Vector2(r * 0.7, -r * 0.7)
	]
	# Стержень пера
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], Color(1, 1, 1, 0.95), 2.5, true)
	
	# Бородки пера (эллиптические лопасти)
	var left_side: PackedVector2Array = [
		c + Vector2(-r * 0.5, r * 0.6),
		c + Vector2(-r * 0.7, 0.0),
		c + Vector2(-r * 0.1, -r * 0.5),
		c + Vector2(r * 0.6, -r * 0.65)
	]
	var right_side: PackedVector2Array = [
		c + Vector2(-r * 0.4, r * 0.6),
		c + Vector2(0.0, r * 0.4),
		c + Vector2(r * 0.5, 0.0),
		c + Vector2(r * 0.7, -r * 0.7)
	]
	draw_polyline(left_side, base_color, 2.0, true)
	draw_polyline(right_side, base_color.lightened(0.2), 2.0, true)


func _draw_ukulele(c: Vector2, r: float) -> void:
	# Укулеле с молнией вокруг
	# Корпус (восьмёрка)
	draw_circle(c + Vector2(-r * 0.2, r * 0.25), r * 0.4, base_color)
	draw_circle(c + Vector2(-r * 0.05, 0.0), r * 0.28, base_color)
	# Гриф
	draw_line(c + Vector2(0, 0), c + Vector2(r * 0.6, -r * 0.6), Color(0.9, 0.9, 0.9), 3.5, true)
	# Головка грифа
	draw_circle(c + Vector2(r * 0.6, -r * 0.6), 3.5, base_color)
	# Резонаторная розетка
	draw_circle(c + Vector2(-r * 0.15, r * 0.2), 3.0, Color(0.08, 0.08, 0.12))
	# Искры молнии
	var spark: PackedVector2Array = [
		c + Vector2(r * 0.2, -r * 0.1),
		c + Vector2(r * 0.5, -r * 0.05),
		c + Vector2(r * 0.35, r * 0.3),
		c + Vector2(r * 0.65, r * 0.45)
	]
	draw_polyline(spark, Color(0.3, 0.9, 1.0), 2.0, true)


func _draw_gasoline(c: Vector2, r: float) -> void:
	# Канистра с бензином и пламя
	var can_rect: Rect2 = Rect2(c.x - r * 0.45, c.y - r * 0.35, r * 0.9, r * 0.85)
	draw_rect(can_rect, base_color, false, 2.5)
	# Ручка канистры
	draw_line(c + Vector2(-r * 0.3, -r * 0.35), c + Vector2(-r * 0.3, -r * 0.55), base_color, 2.5)
	draw_line(c + Vector2(-r * 0.3, -r * 0.55), c + Vector2(r * 0.3, -r * 0.55), base_color, 2.5)
	draw_line(c + Vector2(r * 0.3, -r * 0.55), c + Vector2(r * 0.3, -r * 0.35), base_color, 2.5)
	# Пламя в центре
	var flame: PackedVector2Array = [
		c + Vector2(0, -r * 0.2),
		c + Vector2(r * 0.2, 0.0),
		c + Vector2(r * 0.15, r * 0.25),
		c + Vector2(-r * 0.15, r * 0.25),
		c + Vector2(-r * 0.2, 0.0)
	]
	draw_colored_polygon(flame, Color(1.0, 0.55, 0.1))


func _draw_generic_crystal(c: Vector2, r: float) -> void:
	# Восьмиугольный артефакт
	var pts: PackedVector2Array = []
	for i in range(8):
		var angle: float = i * TAU / 8.0 - PI / 8.0
		pts.append(c + Vector2(cos(angle), sin(angle)) * r * 0.65)
	draw_colored_polygon(pts, Color(base_color.r, base_color.g, base_color.b, 0.4))
	pts.append(pts[0])
	draw_polyline(pts, base_color, 2.5, true)
	draw_circle(c, 3.0, Color(1, 1, 1, 0.9))
