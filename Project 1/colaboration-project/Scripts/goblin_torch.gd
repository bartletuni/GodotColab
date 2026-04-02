extends CharacterBody2D

var entity_id: String = "redgoblin001"

@onready var goblin_red: CharacterBody2D = $"."
@onready var player: CharacterBody2D = $"../Player"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_box: Area2D = $damage_box
@onready var navigation: NavigationAgent2D = $Navigation
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_shape: CollisionShape2D = $hitbox/hitbox_shape

const GOBLIN_MAX_HEALTH = 3
const GOBLIN_SPEED = 250

enum EnemyState {IDLE, WANDER, FOLLOW, ATTACK, DEATH}

var goblin_current_health = GOBLIN_MAX_HEALTH
var current_state = EnemyState.IDLE
var goblin_velocity_modify = 0
var home_position : Vector2
var wander_target : Vector2

@export var knockbackPower: int = 500
@export var ACCEL = 10.0
@export var FRICTION = 6.0


func _ready() -> void:
	home_position = global_position

func _physics_process(delta: float) -> void:
	match current_state:
		
		EnemyState.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, FRICTION * delta)
			move_and_slide()
			animated_sprite_2d.play("Idle")
			
		EnemyState.WANDER:
			var direction = (wander_target - global_position).normalized()
			var target_vel = direction * (GOBLIN_SPEED / 2)
			
			velocity = velocity.lerp(target_vel, ACCEL * delta)
			if direction.x < 0:
				animated_sprite_2d.flip_h = true
			elif direction.x > 0:
				animated_sprite_2d.flip_h = false
			
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
			var intended_velocity = (walkdirection * GOBLIN_SPEED)
			
			navigation.set_velocity(intended_velocity)
			animated_sprite_2d.flip_h = walkdirection.x < 0
			
			if global_position.distance_to(player.global_position) < 50:
				navigation.set_velocity(Vector2.ZERO)
				animated_sprite_2d.play("Idle")
			
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
				
			await get_tree().create_timer(0.3).timeout
			if PlayerData.player_health != 0 and goblin_current_health != 0:
				hitbox_shape.set_deferred("disabled", false)
			
			await get_tree().create_timer(0.3).timeout
			hitbox_shape.set_deferred("disabled", true)
			
			if goblin_current_health != 0:
				hitbox_shape.set_deferred("disabled", true)
				current_state = EnemyState.FOLLOW

		EnemyState.DEATH:
			goblin_current_health = 0
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
		knockback()
		if goblin_current_health == 1:
			health_bar.value = goblin_current_health - 1
			current_state = EnemyState.DEATH
		else:
			goblin_current_health -= 1
			health_bar.value = goblin_current_health
			
func death_anim():
	health_bar.value = goblin_current_health - 1
	#animated_sprite_2d.play("death")
	#await get_tree().create_timer(1.3).timeout
	var gold = preload("res://Assets/gold.tscn").instantiate()
	gold.global_position = global_position
	add_sibling(gold)
	SceneManager.remove_entity(self)
	queue_free()

func _on_idle_timer_timeout() -> void:
	if current_state == EnemyState.IDLE:
		var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		var random_distance = randf_range(0, 400)
		
		wander_target = home_position + (random_direction * random_distance)
		current_state = EnemyState.WANDER


func _on_detection_radius_area_exited(area: Area2D) -> void:
	if area.is_in_group("Player") and goblin_current_health != 0:
		$DeAgro_Timer.start()
		

func _on_de_agro_timer_timeout() -> void:
	current_state = EnemyState.WANDER


func _on_navigation_velocity_computed(safe_velocity: Vector2) -> void:
	var target_velocity = safe_velocity * goblin_velocity_modify
	var weight = ACCEL if target_velocity.length() > 0 else FRICTION
	velocity = velocity.lerp(target_velocity, weight * get_physics_process_delta_time())
	move_and_slide()
	
func knockback():
	if goblin_current_health != 0:
		var knockbackDirection = (player.velocity - velocity).normalized() * knockbackPower
		velocity = knockbackDirection * 1.5
		move_and_slide()
