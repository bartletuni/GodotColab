extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_box: Area2D = $damage_box

const GOBLIN_HEALTH = 3
const GOBLIN_SPEED = 250

enum EnemyState {IDLE, WANDER, FOLLOW, DEATH}

var enemy_health = GOBLIN_HEALTH
var current_state = EnemyState.IDLE
var home_position : Vector2
var wander_target : Vector2


func _ready() -> void:
	$IdleTimer.start()
	home_position = global_position

func _physics_process(delta: float) -> void:
	match current_state:
		EnemyState.IDLE:
			velocity = Vector2.ZERO
			animated_sprite_2d.play("Idle")
		EnemyState.WANDER:
			var direction = (wander_target - global_position).normalized()
			if direction.x < 0:
				animated_sprite_2d.flip_h = true
			elif direction.x > 0:
				animated_sprite_2d.flip_h = false
			velocity = direction * GOBLIN_SPEED/2
			move_and_slide()
			animated_sprite_2d.play("Walk")
			if global_position.distance_to(wander_target) < 10:
				current_state = EnemyState.IDLE
				$IdleTimer.start()
		EnemyState.FOLLOW:
			pass
		EnemyState.DEATH:
			death_anim()



func _on_detection_radius_area_entered(area: Area2D) -> void:
	pass
	
func _on_damage_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player Objects"):
		if enemy_health == 1:
			health_bar.value = enemy_health - 1
			current_state = EnemyState.DEATH
		else:
			enemy_health -= 1
			health_bar.value = enemy_health
			
func death_anim():
	health_bar.value = enemy_health - 1
	animated_sprite_2d.play("death")
	await get_tree().create_timer(1.3).timeout
	queue_free()

func _on_idle_timer_timeout() -> void:
	if current_state == EnemyState.IDLE:
		var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		var random_distance = randf_range(0, 400)
		wander_target = home_position + (random_direction * random_distance)
		current_state = EnemyState.WANDER
