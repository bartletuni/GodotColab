extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var timer: Timer = $"../Timers/Timer"
@onready var reload_timer: Timer = $"../Timers/ReloadTimer"

const SPEED = 450.0
const HEALTH = 5

var player_health = HEALTH

func _physics_process(delta: float) -> void:
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = direction * SPEED
	
	var intX = int(velocity.x)
	var intY = int(velocity.y)
	
	if intX > 0:
		animated_sprite_2d.flip_h = false
	elif intX < 0:
		animated_sprite_2d.flip_h = true
	
	if intX == 0 and intY == 0 and player_health != -1:
		animated_sprite_2d.play("idle")
	elif intX != 0 or intY != 0:
		animated_sprite_2d.play("run")
	
	print(player_health)
	
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if player_health == 0:
		timer.start()
		reload_timer.start()
		
	player_health -= 1
	




func _on_timer_timeout() -> void:
	animated_sprite_2d.play("death")
	


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
