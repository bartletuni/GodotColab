extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius

const GOBLIN_HEALTH = 3

var health = GOBLIN_HEALTH

func _physics_process(delta: float) -> void:
	pass


func _on_detection_radius_area_entered(area: Area2D) -> void:
	
	var direction = global_position.direction_to(player.global_position)
	var detected_bodies = detection_radius.get_overlapping_bodies()
	var bodies_number = detected_bodies.size()
	
	if bodies_number > 0:
		animated_sprite_2d.play("Walk")
		velocity = direction * 300
		move_and_slide()
	
