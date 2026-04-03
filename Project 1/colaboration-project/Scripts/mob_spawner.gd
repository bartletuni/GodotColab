extends Area2D

var entity_id: String = "mobspawner001"

#Array containing all enemies potentially spawned
var goblin_types = [
	preload("res://Assets/Goblin_Red.tscn"),
	preload("res://Assets/Goblin_Red.tscn"),
 	preload("res://Assets/goblin_yellow.tscn")]

@onready var path_follow_2d: PathFollow2D = $Path2D/PathFollow2D
@onready var timer: Timer = $Timer
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_shape: CollisionShape2D = $hitbox/hitbox_shape
@onready var health_bar: ProgressBar = $HealthBar

var spawner_health = 10

func enemy_spawning():
	while WorldData.spawn_on_player == 1:
		goblin_spawn()
		await get_tree().create_timer(3).timeout

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		goblin_spawn()
		timer.start()
		WorldData.spawn_on_player = 1

func goblin_spawn():
	var random_goblin_scene = goblin_types.pick_random()
	var new_goblin = random_goblin_scene.instantiate()
	path_follow_2d.progress_ratio = randf()
	new_goblin.global_position = path_follow_2d.global_position
	add_sibling(new_goblin)

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		WorldData.spawn_on_player = 0


func _on_timer_timeout() -> void:
	enemy_spawning()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player Objects"):
		if spawner_health == 1:
			health_bar.value = spawner_health - 1
			var wood = preload("res://Assets/wood.tscn").instantiate()
			wood.global_position = global_position
			add_sibling(wood)
			SceneManager.remove_entity(self)
			queue_free()
		else:
			spawner_health -= 1
			health_bar.value = spawner_health
			
