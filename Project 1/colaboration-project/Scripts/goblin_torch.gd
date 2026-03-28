extends CharacterBody2D

@onready var goblin_red: CharacterBody2D = $"."
@onready var player: CharacterBody2D = $"../Obstacles/Player"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_box: Area2D = $damage_box
@onready var navigation: NavigationAgent2D = $Navigation
@onready var hitbox: Area2D = $hitbox

const GOBLIN_HEALTH = 3
const GOBLIN_SPEED = 250

enum EnemyState {IDLE, WANDER, FOLLOW, ATTACK, DEATH}

var enemy_health = GOBLIN_HEALTH
var current_state = EnemyState.IDLE
var goblin_velocity_modify = 0
var home_position : Vector2
var wander_target : Vector2


func _ready() -> void:
	home_position = global_position

func _physics_process(_delta: float) -> void:
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
			navigation.target_position = player.global_position
			animated_sprite_2d.play("Walk")
			goblin_velocity_modify = 2.5
			
			var next_path_pos = navigation.get_next_path_position()
			var walkdirection = (next_path_pos - global_position).normalized()
			var intended_velocity = walkdirection * GOBLIN_SPEED
			navigation.set_velocity(intended_velocity)
			animated_sprite_2d.flip_h = walkdirection.x < 0
			if global_position.distance_to(player.global_position) < 85:
				current_state = EnemyState.ATTACK
			
		EnemyState.ATTACK:
			goblin_velocity_modify = 0
			
			if global_position.y + 40 >= player.global_position.y and global_position.y - 40 <= player.global_position.y:
				animated_sprite_2d.play("AttackSide")
			elif global_position.y < player.global_position.y:
				animated_sprite_2d.play("AttackDown")
			else:
				animated_sprite_2d.play("AttackUp")
			
			await get_tree().create_timer(0.6).timeout
			current_state = EnemyState.FOLLOW
			
		EnemyState.DEATH:
			hitbox.set_deferred("disabled", true)
			velocity = Vector2.ZERO
			navigation.set_velocity(Vector2.ZERO)
			death_anim()



func _on_detection_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		current_state = EnemyState.FOLLOW
		$DeAgro_Timer.stop()
	
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


func _on_detection_radius_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player"):
		$DeAgro_Timer.start()
		

func _on_de_agro_timer_timeout() -> void:
	current_state = EnemyState.WANDER


func _on_navigation_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity * goblin_velocity_modify
	move_and_slide()
