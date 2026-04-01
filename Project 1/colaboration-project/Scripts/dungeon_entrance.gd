extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		SceneManager.save_to_disk()
		SceneManager.change_scene("res://Assets/purple_castle_spawn_scene.tscn")
