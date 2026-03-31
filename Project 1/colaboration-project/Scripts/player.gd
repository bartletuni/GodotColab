extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var timer: Timer = $"../Timers/Timer"
@onready var reload_timer: Timer = $"../Timers/ReloadTimer"
@onready var health_bar: ProgressBar = $HealthBar
@onready var shield: ProgressBar = $Shield
@onready var damagebox: Area2D = $damagebox
@onready var attack_timer: Timer = $attack_timer

const SPEED = 450.0
const HEALTH = 5
const SHIELD = 0

func _ready() -> void:
	PlayerData.player_health = HEALTH
	PlayerData.player_shield = SHIELD
	health_bar.value = PlayerData.player_health
	shield.value = PlayerData.player_shield

func _physics_process(_delta: float) -> void:
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var attack_down := Input.is_action_pressed("attack_down")
	var attack_up := Input.is_action_pressed("attack_up")
	var attack_left := Input.is_action_pressed("attack_left")
	var attack_right := Input.is_action_pressed("attack_right")
	
	%HealthBar.value = PlayerData.player_health
	%Shield.value = PlayerData.player_shield
	
	if animated_sprite_2d.animation == "attack_side" and animated_sprite_2d.is_playing():
		velocity = direction * 200
		move_and_slide()
		return
	elif	 animated_sprite_2d.animation == "attack_up" and animated_sprite_2d.is_playing():
		velocity = direction * 200
		move_and_slide()
		return
	elif	 animated_sprite_2d.animation == "attack_down" and animated_sprite_2d.is_playing():
		velocity = direction * 200
		move_and_slide()
		return
	
	if PlayerData.player_health >= 1:
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
	
	if intX == 0 and intY == 0 and PlayerData.player_health != 0:
		animated_sprite_2d.play("idle")
	elif intX != 0 or intY != 0:
		animated_sprite_2d.play("run")
	
	if attack_right == true:
		animated_sprite_2d.flip_h = false
		animated_sprite_2d.play("attack_side")
		attack_hitbox_switch(%right_box)
		
	if attack_left == true:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.play("attack_side")
		attack_hitbox_switch(%left_box)
		
	if attack_up == true:
		animated_sprite_2d.play("attack_up")
		attack_hitbox_switch(%up_box)
		
	if attack_down == true:
		animated_sprite_2d.play("attack_down")
		attack_hitbox_switch(%down_box)
	
	health_bar.max_value = HEALTH
	
	move_and_slide()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

func attack_hitbox_switch(direction):
	await get_tree().create_timer(0.3).timeout
	direction.set_deferred("disabled", false)
	await get_tree().create_timer(0.1).timeout
	direction.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Hazards") or area.is_in_group("Enemies"):
		if PlayerData.player_health == 1:
			animated_sprite_2d.play("death")
			reload_timer.start()
			
		if PlayerData.player_shield > 0:
			PlayerData.player_shield -= 1
			shield.value = PlayerData.player_shield
		else:
			PlayerData.player_health -= 1
			health_bar.value = PlayerData.player_health
		
		await get_tree().create_timer(0.5).timeout
