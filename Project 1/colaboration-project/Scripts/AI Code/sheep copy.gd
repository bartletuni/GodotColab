extends CharacterBody2D

@onready var sheep_red: CharacterBody2D = $"."
@onready var player: CharacterBody2D = $"../Player"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_box: Area2D = $damage_box
@onready var navigation: NavigationAgent2D = $Navigation
@onready var flee_timer: Timer = $FleeTimer
@onready var idle_timer: Timer = $IdleTimer

const SHEEP_MAX_HEALTH = 3
const SHEEP_SPEED = 250
const FLEE_DISTANCE = 400.0
const FLEE_SPEED_MULTIPLIER = 2.5

enum SheepState {IDLE, WANDER, FLEE, DEATH}

var sheep_current_health = SHEEP_MAX_HEALTH
var sheep_current_state = SheepState.IDLE
var sheep_velocity_modify = 0
var home_position : Vector2
var wander_target : Vector2

@export var knockbackPower: int = 5000


func _ready() -> void:
	home_position = global_position
	navigation.avoidance_enabled = true

func _physics_process(_delta: float) -> void:
	match sheep_current_state:
		
		SheepState.IDLE:
			sheep_velocity_modify = 0
			velocity = Vector2.ZERO
			animated_sprite_2d.play("Idle")
			
		SheepState.WANDER:
			sheep_velocity_modify = 0
			var direction = (wander_target - global_position).normalized()
			
			if direction.x < 0:
				animated_sprite_2d.flip_h = true
			elif direction.x > 0:
				animated_sprite_2d.flip_h = false
			
			velocity = direction * SHEEP_SPEED/2
			move_and_slide()
			animated_sprite_2d.play("Walk")
			
			if global_position.distance_to(wander_target) < 10:
				sheep_current_state = SheepState.IDLE
				idle_timer.start()
				
		SheepState.FLEE:
			var flee_direction = global_position - player.global_position
			if flee_direction == Vector2.ZERO:
				flee_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
			
			navigation.target_position = global_position + (flee_direction.normalized() * FLEE_DISTANCE)
			sheep_velocity_modify = 0
			animated_sprite_2d.play("Walk")
			
			var next_path_pos = navigation.get_next_path_position()
			var walkdirection = (next_path_pos - global_position).normalized()
			if walkdirection == Vector2.ZERO:
				walkdirection = flee_direction.normalized()
			
			velocity = walkdirection * SHEEP_SPEED * FLEE_SPEED_MULTIPLIER
			move_and_slide()
			if walkdirection.x != 0:
				animated_sprite_2d.flip_h = walkdirection.x < 0
			
			#if global_position.distance_to(player.global_position) < 50:
				#navigation.set_velocity(Vector2.ZERO)
				#animated_sprite_2d.play("Idle")
			#
			#if global_position.distance_to(player.global_position) < 85:
				#sheep_current_state = SheepState.FLEE

		SheepState.DEATH:
			sheep_current_health = 0
			velocity = Vector2.ZERO
			navigation.set_velocity(Vector2.ZERO)
			death_anim()


func _on_detection_radius_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		sheep_current_state = SheepState.FLEE
		flee_timer.stop()
	
func _on_damage_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player Objects"):
		knockback()
		if sheep_current_health == 1:
			health_bar.value = sheep_current_health - 1
			sheep_current_state = SheepState.DEATH
		else:
			sheep_current_health -= 1
			health_bar.value = sheep_current_health
			
func death_anim():
	health_bar.value = sheep_current_health - 1
	var meat = preload("res://Assets/meat.tscn").instantiate()
	meat.global_position = global_position
	add_sibling(meat)
	queue_free()

func _on_idle_timer_timeout() -> void:
	if sheep_current_state == SheepState.IDLE:
		var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		var random_distance = randf_range(0, 400)
		
		wander_target = home_position + (random_direction * random_distance)
		sheep_current_state = SheepState.WANDER


func _on_detection_radius_area_exited(area: Area2D) -> void:
	
	if area.is_in_group("Player") and sheep_current_health != 0:
		flee_timer.start()
		

func _on_flee_timer_timeout() -> void:
	sheep_current_state = SheepState.WANDER


func _on_navigation_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity * sheep_velocity_modify
	move_and_slide()
	
func knockback():
	if sheep_current_health != 0:
		var knockbackDirection = (player.velocity - velocity).normalized() * knockbackPower
		velocity = knockbackDirection * 1.5
		move_and_slide()
