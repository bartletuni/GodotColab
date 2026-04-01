# scene_manager.gd
# ─────────────────────────────────────────────────────────────────────────────
# AUTOLOAD SINGLETON  –  add this in:
#   Project > Project Settings > Autoload > path: res://scene_manager.gd
#                                           name: SceneManager
#
# This node lives for the entire lifetime of the game. Any script can read
# from or write to it with:  SceneManager.<property_or_method>
# ─────────────────────────────────────────────────────────────────────────────
extends Node

# ── Save file location ────────────────────────────────────────────────────────
const SAVE_PATH := "user://savegame.json"

# ── Player state ─────────────────────────────────────────────────────────────
# Mirrors whatever your player node tracks. Add more fields as you need them.
var player_data := {
	"position_x":  0.0,
	"position_y":  0.0,
	"health":      100.0,
	"max_health":  100.0,
	# Inventory: Array of { "item": String, "quantity": int }
	"inventory":   [],
	# Any extra player flags/stats you want to persist
	"extra":       {}
}

# ── World entity state ────────────────────────────────────────────────────────
# Key:   entity_id  (String – must be unique per entity, see _make_entity_id)
# Value: WorldEntityData  (defined in world_entity_data.gd)
var world_entities: Dictionary = {}

# Track which scene the player was last in, so you can reload it on continue.
var current_scene_path: String = ""

# ── Scene-change helper ───────────────────────────────────────────────────────
# Call this instead of get_tree().change_scene_to_file() everywhere so that
# world state is always captured before leaving.
func go_to_scene(new_scene_path: String) -> void:
	save_world_from_scene(get_tree())
	current_scene_path = new_scene_path
	get_tree().change_scene_to_file(new_scene_path)


# ═════════════════════════════════════════════════════════════════════════════
#  CAPTURING WORLD STATE  (call before changing scenes or on autosave)
# ═════════════════════════════════════════════════════════════════════════════

# Walk every node in the current scene and capture state from any node that
# belongs to a recognised group. You can call this any time – it merges
# into world_entities so previously-seen-but-not-present entities are kept.
func save_world_from_scene(tree: SceneTree) -> void:
	# ── Player ────────────────────────────────────────────────────────────────
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		_capture_player(players[0])

	# ── Enemies & creatures ───────────────────────────────────────────────────
	for node in tree.get_nodes_in_group("goblin_red"):
		_capture_entity(node, "goblin_red")

	for node in tree.get_nodes_in_group("sheep"):
		_capture_entity(node, "sheep")

	# ── Generic "saveable" group ──────────────────────────────────────────────
	# Tag any other spawned node with the group "saveable" and give it a
	# property  entity_type: String  so we can record what it is.
	for node in tree.get_nodes_in_group("saveable"):
		var etype: String = node.get("entity_type") if node.get("entity_type") else "unknown"
		_capture_entity(node, etype)


# Pull data out of the player node into player_data.
# Your player script should expose these properties; adjust names as needed.
func _capture_player(player: Node) -> void:
	if player.get("position") != null:
		player_data["position_x"] = player.position.x
		player_data["position_y"] = player.position.y

	if player.get("health") != null:
		player_data["health"] = player.health

	if player.get("max_health") != null:
		player_data["max_health"] = player.max_health

	# If your player has an inventory node/script, call its serialise method.
	# Convention: the player exposes get_inventory_data() -> Array
	if player.has_method("get_inventory_data"):
		player_data["inventory"] = player.get_inventory_data()

	# Any extra flags your player script exposes via get_extra_data() -> Dictionary
	if player.has_method("get_extra_data"):
		player_data["extra"] = player.get_extra_data()


# Pull data out of a world entity node into world_entities.
func _capture_entity(node: Node, entity_type: String) -> void:
	var eid := _make_entity_id(node)
	var data: WorldEntityData

	# Re-use existing record if we already have one; otherwise create fresh.
	if world_entities.has(eid):
		data = world_entities[eid]
	else:
		data = WorldEntityData.new()
		data.entity_id   = eid
		data.entity_type = entity_type
		# scene_path lets us respawn the entity later.
		# Convention: expose  var scene_path: String  on the script, OR we
		# fall back to the scene's filename.
		if node.get("scene_path") != null:
			data.scene_path = node.scene_path
		else:
			data.scene_path = node.scene_file_path   # built-in on instanced scenes

	# Always refresh mutable state
	if node.get("position") != null:
		data.position = node.position

	if node.get("health") != null:
		data.health = node.health

	if node.get("max_health") != null:
		data.max_health = node.max_health

	if node.has_method("get_inventory_data"):
		data.inventory = node.get_inventory_data()

	if node.has_method("get_extra_data"):
		data.extra = node.get_extra_data()

	world_entities[eid] = data


# Build a stable unique ID for an entity.
# Best practice: give every spawnable node a property  entity_id: String
# and set it to something deterministic (e.g. "goblin_red_3") when you spawn
# it.  We fall back to the node's name if the property isn't there.
func _make_entity_id(node: Node) -> String:
	if node.get("entity_id") != null and node.entity_id != "":
		return node.entity_id
	return node.name   # name is stable within a scene but may collide across scenes


# ═════════════════════════════════════════════════════════════════════════════
#  RESTORING WORLD STATE  (call after a scene finishes loading)
# ═════════════════════════════════════════════════════════════════════════════

# Respawns and restores all tracked entities in the freshly-loaded scene.
# Typical usage inside the scene's _ready():
#     SceneManager.load_world_into_scene(get_tree(), $YourSpawnParentNode)
func load_world_into_scene(tree: SceneTree, spawn_parent: Node = null) -> void:
	# ── Restore player ────────────────────────────────────────────────────────
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		_restore_player(players[0])

	# ── Restore world entities ────────────────────────────────────────────────
	# Decide where newly-spawned nodes will live in the scene tree.
	var parent: Node = spawn_parent if spawn_parent else tree.current_scene

	# Build a set of entity_ids already present in the scene so we
	# don't double-spawn things that are placed in the editor.
	var present_ids := {}
	for group in ["goblin_red", "sheep", "saveable"]:
		for node in tree.get_nodes_in_group(group):
			var eid := _make_entity_id(node)
			present_ids[eid] = node
			# Still restore their runtime state even if they're already there
			if world_entities.has(eid):
				_restore_entity(node, world_entities[eid])

	# Now spawn anything that was saved but isn't in the scene yet.
	for eid in world_entities:
		if present_ids.has(eid):
			continue   # already handled above
		var data: WorldEntityData = world_entities[eid]
		if data.scene_path == "":
			continue   # can't respawn without a scene path
		_spawn_entity(data, parent)


# Push saved player values back onto the player node.
func _restore_player(player: Node) -> void:
	if player.get("position") != null:
		player.position = Vector2(player_data["position_x"], player_data["position_y"])

	if player.get("health") != null:
		player.health = player_data["health"]

	if player.get("max_health") != null:
		player.max_health = player_data["max_health"]

	# Convention: player exposes  set_inventory_data(data: Array)
	if player.has_method("set_inventory_data") and player_data["inventory"].size() > 0:
		player.set_inventory_data(player_data["inventory"])

	if player.has_method("set_extra_data") and player_data["extra"].size() > 0:
		player.set_extra_data(player_data["extra"])


# Push saved entity values back onto an already-existing node.
func _restore_entity(node: Node, data: WorldEntityData) -> void:
	if node.get("position") != null:
		node.position = data.position

	if node.get("health") != null and data.health >= 0:
		node.health = data.health

	if node.get("max_health") != null and data.max_health >= 0:
		node.max_health = data.max_health

	if node.has_method("set_inventory_data") and data.inventory.size() > 0:
		node.set_inventory_data(data.inventory)

	if node.has_method("set_extra_data") and data.extra.size() > 0:
		node.set_extra_data(data.extra)


# Instantiate a scene from disk and restore its state, then add to the tree.
func _spawn_entity(data: WorldEntityData, parent: Node) -> void:
	if not ResourceLoader.exists(data.scene_path):
		push_warning("SceneManager: cannot find scene '%s' for entity '%s'" \
				% [data.scene_path, data.entity_id])
		return

	var packed: PackedScene = load(data.scene_path)
	var node: Node = packed.instantiate()

	# Stamp the entity_id back on so _make_entity_id() returns the right key.
	if node.get("entity_id") != null:
		node.entity_id = data.entity_id

	parent.add_child(node)
	_restore_entity(node, data)


# ═════════════════════════════════════════════════════════════════════════════
#  REMOVING ENTITIES  (call when an entity is permanently killed/destroyed)
# ═════════════════════════════════════════════════════════════════════════════

# Mark an entity as gone so it won't be respawned next time the scene loads.
# Call this from the entity's death/destroy logic:
#     SceneManager.remove_entity(self)
func remove_entity(node: Node) -> void:
	var eid := _make_entity_id(node)
	world_entities.erase(eid)


# ═════════════════════════════════════════════════════════════════════════════
#  DISK  SAVE / LOAD
# ═════════════════════════════════════════════════════════════════════════════

# Serialise everything to JSON and write to disk.
# Always captures current scene state first, then writes.
func save_to_disk(tree: SceneTree) -> void:
	save_world_from_scene(tree)

	var entities_raw := {}
	for eid in world_entities:
		entities_raw[eid] = world_entities[eid].to_dict()

	var save_data := {
		"current_scene": current_scene_path,
		"player":        player_data,
		"entities":      entities_raw
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SceneManager: failed to open save file for writing.")
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("SceneManager: game saved to ", SAVE_PATH)


# Read the JSON from disk and restore all state into memory.
# After calling this, call go_to_scene(current_scene_path) to resume.
func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("SceneManager: no save file found at " + SAVE_PATH)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SceneManager: failed to open save file for reading.")
		return false

	var json_text  := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SceneManager: save file is corrupt or unreadable.")
		return false

	current_scene_path = parsed.get("current_scene", "")
	player_data        = parsed.get("player", player_data)

	world_entities.clear()
	var entities_raw: Dictionary = parsed.get("entities", {})
	for eid in entities_raw:
		world_entities[eid] = WorldEntityData.from_dict(entities_raw[eid])

	print("SceneManager: game loaded from ", SAVE_PATH)
	return true


# ═════════════════════════════════════════════════════════════════════════════
#  CONVENIENCE ACCESSORS
# ═════════════════════════════════════════════════════════════════════════════

# Quick check: has this entity been recorded (and therefore should exist)?
func entity_exists(entity_id: String) -> bool:
	return world_entities.has(entity_id)

# Retrieve a single entity's saved data by id (returns null if not found).
func get_entity_data(entity_id: String) -> WorldEntityData:
	return world_entities.get(entity_id, null)

# Check whether a valid save file is on disk (useful for greying out "Continue")
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Wipe everything – useful for starting a new game.
func reset() -> void:
	player_data = {
		"position_x": 0.0, "position_y": 0.0,
		"health": 100.0, "max_health": 100.0,
		"inventory": [], "extra": {}
	}
	world_entities.clear()
	current_scene_path = ""
