extends StaticBody2D

var entity_id: String = "purplecastle001"

func _on_enterbox_area_entered(area: Area2D) -> void:
	print("workiing")
	if area.is_in_group("Player"):
		SceneManager.save_to_disk()
		SceneManager.change_scene("res://Assets/purple_castle_spawn_scene.tscn")
