extends Area2D

@export var player_spawn_position: Vector2


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		SceneManager.player_spawn_position = player_spawn_position
		get_tree().change_scene_to_file("res://Assets/purple_castle_spawn_scene.tscn")
