class_name DamageNumber
extends Node3D
## Всплывающие цифры урона над врагами в стиле Risk of Rain.
## Белые для обычных попаданий, желтые для критических ударов.

@onready var label: Label3D = $Label3D

func popup(amount: float, is_crit: bool, world_pos: Vector3) -> void:
	global_position = world_pos + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.6), randf_range(-0.3, 0.3))
	
	if label:
		label.text = str(int(amount))
		if is_crit:
			label.modulate = Color(1.0, 0.85, 0.15, 1.0)
			label.outline_modulate = Color(0.6, 0.2, 0.0, 1.0)
			label.font_size = 28
			scale = Vector3(1.3, 1.3, 1.3)
		else:
			label.modulate = Color(1.0, 1.0, 1.0, 1.0)
			label.outline_modulate = Color(0.1, 0.1, 0.15, 1.0)
			label.font_size = 22
			
	var tween = create_tween()
	# Движение вверх и плавное исчезновение
	tween.tween_property(self, "position:y", position.y + 1.8, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.65)
	tween.tween_callback(queue_free)
