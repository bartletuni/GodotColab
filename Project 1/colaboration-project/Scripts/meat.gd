extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player") and PlayerData.player_health < 4:
		PlayerData.player_health += 2
		queue_free()
	elif area.is_in_group("Player") and PlayerData.player_health == 4:
		PlayerData.player_health += 1
		queue_free()
