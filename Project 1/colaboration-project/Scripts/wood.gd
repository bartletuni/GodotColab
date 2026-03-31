extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		PlayerData.player_wood += 1
		queue_free()
