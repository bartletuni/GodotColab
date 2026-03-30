extends Node2D

const MINI_SHROOM = preload("uid://bcsyweygwkgon")
const PURPLE_CASTLE = preload("uid://vxd1uvbooi8m")
const MOB_SPAWNER = preload("uid://b4g1u11f7i2il")

var mushroom_spawn_rate = 0.005
var spawner_spawn_rate = 0.0005
var purple_castle_spawn_rate = 0.0001

var objects = [MINI_SHROOM, MOB_SPAWNER, PURPLE_CASTLE]
var spawn_rates = [mushroom_spawn_rate, spawner_spawn_rate, purple_castle_spawn_rate]
var spawn_rate = 0

func _ready() -> void:
	random_spawn()
	randomize()
	

func random_spawn():
	for object in objects:
		var used_cells = %Ground.get_used_cells()
		
		for cell in used_cells:
			if randf() < spawn_rates[spawn_rate]:
				var new_object = object.instantiate()
				new_object.position = %Ground.map_to_local(cell)
				add_child(new_object)
		
		spawn_rate += 1

#func mushroom_spawn():
	#var used_cells = %Ground.get_used_cells()
	#
	#for cell in used_cells:
		#if randf() < mushroom_spawn_rate:
			#var new_object = MINI_SHROOM.instantiate()
			#new_object.position = %Ground.map_to_local(cell)
			#add_child(new_object)

#func purple_castle_spawn():
	#var used_cells = %Ground.get_used_cells()
	#
	#for cell in used_cells:
		#if randf() < purple_castle_spawn_rate:
			#var new_object = PURPLE_CASTLE.instantiate()
			#new_object.position = %Ground.map_to_local(cell)
			#add_child(new_object)
#
#func spawner_spawn():
	#var used_cells = %Ground.get_used_cells()
	#
	#for cell in used_cells:
		#if randf() < spawner_spawn_rate:
			#var new_object = MOB_SPAWNER.instantiate()
			#new_object.position = %Ground.map_to_local(cell)
			#add_child(new_object)
