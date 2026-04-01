extends StaticBody2D

var entity_id: String = "goldmine001"

@onready var activate: Area2D = $activate
@onready var enter: Area2D = $enter
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _on_enter_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		pass
	else:
		pass
	


func _on_activate_area_entered(area: Area2D) -> void:
	if PlayerData.player_wood >= 10 and area.is_in_group("Player"):
		PlayerData.player_wood -= 10
		enter.set_deferred("disabled", false)
		activate.set_deferred("disabled", true)
		animated_sprite_2d.play("Active")
	else:
		pass
		
