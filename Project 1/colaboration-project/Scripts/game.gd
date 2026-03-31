extends Node2D

const MINI_SHROOM = preload("uid://bcsyweygwkgon")
const PURPLE_CASTLE = preload("uid://vxd1uvbooi8m")
const MOB_SPAWNER = preload("uid://b4g1u11f7i2il")
const POISON_BONE = preload("uid://dx4blwinm0bcr")
const ROCK_001 = preload("uid://bmo4uoqfsj2xi")
const ROCK_002 = preload("uid://c2q1bmcgkm16u")

var mushroom_spawn_rate = 0.0025
var spawner_spawn_rate = 0.0005
var purple_castle_spawn_rate = 0.0001
var poison_bone_spawn_rate = 0.0025
var rock001_spawn_rate = 0.0025
var rock002_spawn_rate = 0.0025


var objects = [MINI_SHROOM, MOB_SPAWNER, PURPLE_CASTLE, POISON_BONE, ROCK_001, ROCK_002]
var spawn_rates = [mushroom_spawn_rate, spawner_spawn_rate, purple_castle_spawn_rate, poison_bone_spawn_rate, rock001_spawn_rate, rock002_spawn_rate]
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
