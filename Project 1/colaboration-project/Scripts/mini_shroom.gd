extends Area2D

@onready var player: CharacterBody2D = $"../Player"
@onready var health_bar: ProgressBar = $"../Player/HealthBar"


func _on_body_entered(body: Node2D) -> void:
	player.player_health += 1
	if player.player_health != 1:
		health_bar.value = player.player_health
		queue_free()
