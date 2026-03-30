extends Node2D

const MINI_SHROOM = preload("uid://bcsyweygwkgon")
const PURPLE_CASTLE = preload("uid://vxd1uvbooi8m")
const MOB_SPAWNER = preload("uid://b4g1u11f7i2il")

var mushroom_spawn_rate = 0.005
var purple_castle_spawn_rate = 0.0001
var spawner_spawn_rate = 0.0005

func _ready() -> void:
	mushroom_spawn()
	purple_castle_spawn()
	spawner_spawn()
	randomize()
	
func mushroom_spawn():
	var used_cells = %Ground.get_used_cells()
	
	for cell in used_cells:
		if randf() < mushroom_spawn_rate:
			var new_object = MINI_SHROOM.instantiate()
			new_object.position = %Ground.map_to_local(cell)
			add_child(new_object)

func purple_castle_spawn():
	var used_cells = %Ground.get_used_cells()
	
	for cell in used_cells:
		if randf() < purple_castle_spawn_rate:
			var new_object = PURPLE_CASTLE.instantiate()
			new_object.position = %Ground.map_to_local(cell)
			add_child(new_object)

func spawner_spawn():
	var used_cells = %Ground.get_used_cells()
	
	for cell in used_cells:
		if randf() < spawner_spawn_rate:
			var new_object = MOB_SPAWNER.instantiate()
			new_object.position = %Ground.map_to_local(cell)
			add_child(new_object)
