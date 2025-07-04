class_name DisposableParticles
extends GPUParticles2D


func start(delete_after := 4.0):
	show()
	emitting = true
	await get_tree().create_timer(delete_after).timeout
	queue_free()
