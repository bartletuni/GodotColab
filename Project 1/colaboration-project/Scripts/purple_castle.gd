extends StaticBody2D

func _on_enterbox_area_entered(area: Area2D) -> void:
	print("workiing")
	if area.is_in_group("Player"):
		get_tree().change_scene_to_file("res://Assets/purple_castle_spawn_scene.tscn")
