extends Area2D

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var timer: Timer = $Timer
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_shape: CollisionShape2D = $hitbox/hitbox_shape
@onready var health_bar: ProgressBar = $HealthBar

var spawner_health = 10

func enemy_spawning():
	
	while WorldData.spawn_on_player == 1:
		var goblin_red = preload("res://Assets/Goblin_Red.tscn").instantiate()
		path_follow_2d.progress_ratio = randf()
		goblin_red.global_position = path_follow_2d.global_position
		add_sibling(goblin_red)
		await get_tree().create_timer(3).timeout

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		var goblin_red = preload("res://Assets/Goblin_Red.tscn").instantiate()
		path_follow_2d.progress_ratio = randf()
		goblin_red.global_position = path_follow_2d.global_position
		add_sibling(goblin_red)
		timer.start()
		WorldData.spawn_on_player = 1

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		WorldData.spawn_on_player = 0


func _on_timer_timeout() -> void:
	enemy_spawning()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player Objects"):
		if spawner_health == 1:
			health_bar.value = spawner_health - 1
			queue_free()
		else:
			spawner_health -= 1
			health_bar.value = spawner_health
			
