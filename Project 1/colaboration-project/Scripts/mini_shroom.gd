extends Area2D

@onready var health_bar: ProgressBar = $"../Player/HealthBar"
@onready var additional_health: ProgressBar = $"../Player/AdditionalHealth"
@onready var player: CharacterBody2D = $"../Player"

func _on_area_entered(_area: Area2D) -> void:
	if PlayerData.player_health == 5 and PlayerData.player_shield < 5:
		additional_health.value += 1
		PlayerData.player_shield += 1
		queue_free()
	elif PlayerData.player_health < 5:
		PlayerData.player_health += 1
		health_bar.value = PlayerData.player_health
		queue_free()
