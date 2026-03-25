extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var timer: Timer = $"../Timers/Timer"
@onready var reload_timer: Timer = $"../Timers/ReloadTimer"
@onready var health_bar: ProgressBar = $HealthBar
@onready var additional_health: ProgressBar = $AdditionalHealth
@onready var damagebox: Area2D = $damagebox
@onready var right_box: CollisionShape2D = $damagebox/right_box
@onready var left_box: CollisionShape2D = $damagebox/left_box
@onready var attack_timer: Timer = $attack_timer

const SPEED = 450.0
const HEALTH = 5
const SHIELD = 0

var player_shield = SHIELD 
var player_health = HEALTH
#var facing = animated_sprite_2d.flip_h
var is_attacking = false

func _physics_process(delta: float) -> void:
	
	var facing = animated_sprite_2d.flip_h
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var attack_down := Input.is_action_just_pressed("attack_down")
	var attack_up := Input.is_action_just_pressed("attack_up")
	var attack_left := Input.is_action_just_pressed("attack_left")
	var attack_right := Input.is_action_just_pressed("attack_right")
	
	if animated_sprite_2d.animation == "attack_side" and animated_sprite_2d.is_playing():
		move_and_slide()
		return
	
	if player_health >= 1:
		velocity = direction * SPEED
	else:
		velocity.x = 0
		velocity.y = 0
	
	var intX = int(velocity.x)
	var intY = int(velocity.y)
	
	if intX > 0:
		animated_sprite_2d.flip_h = false
	elif intX < 0:
		animated_sprite_2d.flip_h = true
	
	#if animated_sprite_2d.animation == "attack_side":
		#return
	
	if intX == 0 and intY == 0 and player_health != 0:
		animated_sprite_2d.play("idle")
	elif intX != 0 or intY != 0:
		animated_sprite_2d.play("run")
	
	if attack_right == true:
		animated_sprite_2d.play("attack_side")
		right_box.set_deferred("disabled", false)
		await get_tree().create_timer(1.1).timeout
		right_box.set_deferred("disabled", true)
		await get_tree().create_timer(1.0).timeout
		
		attack_timer.start()
	
	health_bar.max_value = HEALTH
	
	print(player_health)
	
	move_and_slide()
	

func _on_timer_timeout() -> void:
	animated_sprite_2d.play("death")
	


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Hazards") or area.is_in_group("Enemies"):
		if player_health == 1:
			timer.start()
			reload_timer.start()

		if player_shield > 0:
			player_shield -= 1
			additional_health.value = player_shield
		else:
			player_health -= 1
			health_bar.value = player_health


#func _on_attack_timer_timeout() -> void:
	#if animated_sprite_2d.flip_h == false:
		#animated_sprite_2d.play("attack_side")
		#right_box.set_deferred("disabled", false)
		#await get_tree().create_timer(1.1).timeout
		#right_box.set_deferred("disabled", true)
		#await get_tree().create_timer(1.0).timeout
	#elif animated_sprite_2d.flip_h == true:
		#animated_sprite_2d.flip_h = true
		#animated_sprite_2d.play("attack_side")
		#left_box.set_deferred("disabled", false)
		#await get_tree().create_timer(1.1).timeout
		#left_box.set_deferred("disabled", true)
		#animated_sprite_2d.flip_h = false
		#await get_tree().create_timer(1.0).timeout
