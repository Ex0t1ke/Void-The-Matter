class_name OneShotVFX
extends Node3D
## Легковесный контроллер одноразовых визуальных эффектов (VFX).
## Автоматически удаляет узел после завершения анимации или партиклов.

@export var lifetime: float = 0.5
@export var fade_out: bool = true


func _ready() -> void:
	var particles: GPUParticles3D = find_child("*", true, false) as GPUParticles3D
	if particles:
		particles.emitting = true
		particles.one_shot = true
		lifetime = maxf(lifetime, particles.lifetime + 0.1)
		
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_finish)


func _on_finish() -> void:
	if fade_out:
		var tween: Tween = create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.1)
		tween.tween_callback(queue_free)
	else:
		queue_free()
