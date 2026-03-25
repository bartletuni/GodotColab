extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_radius: Area2D = $detection_radius
@onready var health_bar: ProgressBar = $HealthBar
@onready var damage_box: Area2D = $damage_box

const GOBLIN_HEALTH = 3

var enemy_health = GOBLIN_HEALTH

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
	
func _on_damage_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player Objects"):
		if enemy_health == 1:
			health_bar.value = enemy_health - 1
			animated_sprite_2d.play("death")
			await get_tree().create_timer(1.3).timeout
			queue_free()
		else:
			enemy_health -= 1
			health_bar.value = enemy_health
