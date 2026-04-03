extends RigidBody2D

@onready var explosion_shape: CollisionShape2D = $ExplosionRadius/ExplosionShape
@onready var dynamite: RigidBody2D = $"."

#func _ready() -> void:
	#$AnimatedSprite2D.play("Primed")
	
func _on_fuse_timer_timeout() -> void:
	dynamite.set_deferred("freeze", true)
	$AnimatedSprite2D.play("Explosion")
	explosion_shape.set_deferred("disabled", false)
	await get_tree().create_timer(0.1).timeout
	explosion_shape.set_deferred("disabled", true)
	await get_tree().create_timer(0.3).timeout
	queue_free()
