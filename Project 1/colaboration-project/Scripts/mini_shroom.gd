extends Area2D
@onready var player: CharacterBody2D = $"../../Player"
@onready var health_bar: ProgressBar = $"../../Player/HealthBar"
@onready var additional_health: ProgressBar = $"../../Player/AdditionalHealth"

func _on_body_entered(body: Node2D) -> void:
	
	if player.player_health == 5 and player.player_shield < 5:
		additional_health.value += 1
		player.player_shield += 1
		queue_free()
	elif player.player_health < 5:
		player.player_health += 1
		health_bar.value = player.player_health
		queue_free()
