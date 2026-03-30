extends Area2D

const player = preload("uid://be7iyxjfkhmky")

func _on_area_entered(area: Area2D) -> void:
	if PlayerData.player_health == 5 and PlayerData.player_shield < 5 and area.is_in_group("Player"):
		PlayerData.player_shield += 1
		queue_free()
	elif PlayerData.player_health < 5 and area.is_in_group("Player"):
		PlayerData.player_health += 1
		queue_free()
