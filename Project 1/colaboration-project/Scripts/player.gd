extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var timer: Timer = $"../Timers/Timer"
@onready var reload_timer: Timer = $"../Timers/ReloadTimer"
@onready var health_bar: ProgressBar = $HealthBar
@onready var additional_health: ProgressBar = $AdditionalHealth

const SPEED = 450.0
const HEALTH = 5
const SHIELD = 0

var player_shield = SHIELD 
var player_health = HEALTH + 1

func _physics_process(delta: float) -> void:
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
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
	
	if intX == 0 and intY == 0 and player_health != 0:
		animated_sprite_2d.play("idle")
	elif intX != 0 or intY != 0:
		animated_sprite_2d.play("run")
	
	health_bar.max_value = HEALTH
	
	print(player_health)
	
	move_and_slide()
	

#func _on_hitbox_body_entered(body: Node2D) -> void:
	#if body.is_in_group("Hazards"):
		#print("wee")	
#
	#if player_health == 1:
		#timer.start()
		#reload_timer.start()
	#
	#if player_shield > 0:
		#player_shield -= 1
		#additional_health.value = player_shield
	#else:
		#player_health -= 1
		#health_bar.value = player_health
	

func _on_timer_timeout() -> void:
	animated_sprite_2d.play("death")
	


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Hazards"):
		if player_health == 1:
			timer.start()
			reload_timer.start()

		if player_shield > 0:
			player_shield -= 1
			additional_health.value = player_shield
		else:
			player_health -= 1
			health_bar.value = player_health
