# scene_manager.gd
# =============================================================================
# AUTOLOAD SINGLETON
# Register in: Project > Project Settings > Autoload
#   Path: res://scene_manager.gd
#   Name: SceneManager
#
# HOW IT WORKS
# ------------
# 1. Call SceneManager.change_scene("res://my_scene.tscn") instead of
#    get_tree().change_scene_to_file(). This captures all entity and player
#    state from the CURRENT scene before it is freed, then changes scene.
#
# 2. SceneManager listens for the new scene root to appear in the tree.
#    Once it does, it automatically restores all saved state onto matching
#    nodes — both editor-placed and runtime-spawned entities.
#
# 3. For runtime-spawned entities, call SceneManager.restore_entity(node)
#    immediately after adding the node to the scene tree so its saved state
#    (health, position, etc.) is pushed onto it right away.
#
# ENTITY REQUIREMENTS
# -------------------
# Every saveable node must:
#   - Have  var entity_id: String = "some_unique_id"  (set in Inspector or on spawn)
#   - Belong to at least one of these groups: "player", "goblin_red", "sheep",
#     or "saveable" (for any other type)
#
# Optionally expose these for richer save data:
#   - var health: float
#   - var max_health: float
#   - func get_inventory_data() -> Array      (return your inventory array)
#   - func set_inventory_data(d: Array)
#   - func get_extra_data() -> Dictionary     (any other state you want saved)
#   - func set_extra_data(d: Dictionary)
# =============================================================================

extends Node


# ── Inner class ───────────────────────────────────────────────────────────────
# Holds the saved state for a single world entity. Keeping this as an inner
# class means there is only one file to manage — no separate resource script.
class EntityData:
	var entity_id:   String  = ""
	var entity_type: String  = ""
	var scene_path:  String  = ""      # used to respawn runtime entities
	var position:    Vector2 = Vector2.ZERO
	var health:      float   = -1.0    # -1 = entity has no health stat
	var max_health:  float   = -1.0
	var inventory:   Array   = []
	var extra:       Dictionary = {}

	func to_dict() -> Dictionary:
		return {
			"entity_id":   entity_id,
			"entity_type": entity_type,
			"scene_path":  scene_path,
			"position_x":  position.x,
			"position_y":  position.y,
			"health":      health,
			"max_health":  max_health,
			"inventory":   inventory,
			"extra":       extra,
		}

	static func from_dict(d: Dictionary) -> EntityData:
		var e       = EntityData.new()
		e.entity_id   = d.get("entity_id",   "")
		e.entity_type = d.get("entity_type", "")
		e.scene_path  = d.get("scene_path",  "")
		e.position    = Vector2(d.get("position_x", 0.0), d.get("position_y", 0.0))
		e.health      = d.get("health",      -1.0)
		e.max_health  = d.get("max_health",  -1.0)
		e.inventory   = d.get("inventory",   [])
		e.extra       = d.get("extra",       {})
		return e


# ── Constants ─────────────────────────────────────────────────────────────────
const SAVE_PATH   := "user://savegame.json"

# All groups SceneManager will scan when saving the world.
# Add any new enemy/creature group names here.
const ENTITY_GROUPS := ["Enemies", "Hazards", "Player", "Player Objects", "Obstacles", "Pickups"]


# ── In-memory state ───────────────────────────────────────────────────────────
# Player data is stored separately because it has a slightly different shape.
var _player_data: Dictionary = {
	"position_x": 0.0,
	"position_y": 0.0,
	"health":     100.0,
	"max_health": 100.0,
	"inventory":  [],
	"extra":      {},
}

# entity_id → EntityData for every tracked world entity.
var _entities: Dictionary = {}

# The scene we should return to if the player loads from disk.
var _saved_scene_path: String = ""

# Set to true while a scene change is in progress so the node_added handler
# knows to run a restore pass when the new scene root arrives.
var _restoring: bool = false


# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Watch for the new scene root to arrive after a change_scene call.
	# child_entered_tree fires for every node added anywhere in the tree, so
	# we filter carefully inside _on_node_added.
	get_tree().node_added.connect(_on_node_added)


# ═════════════════════════════════════════════════════════════════════════════
#  PUBLIC API — scene changing
# ═════════════════════════════════════════════════════════════════════════════

# Call this everywhere instead of get_tree().change_scene_to_file().
# It captures the current world state BEFORE the old scene is freed,
# then performs the scene change normally.
func change_scene(path: String) -> void:
	_capture_all(get_tree())
	_saved_scene_path = path
	_restoring = true
	get_tree().change_scene_to_file(path)


# ═════════════════════════════════════════════════════════════════════════════
#  PUBLIC API — runtime-spawned entities
# ═════════════════════════════════════════════════════════════════════════════

# Call this immediately after add_child(node) for any runtime-spawned entity.
# If we have saved data for this entity_id, it will be pushed onto the node.
# If we have no record yet, the node's current state is captured and stored.
func restore_entity(node: Node) -> void:
	var eid: String = _get_id(node)
	if eid == "":
		push_warning("SceneManager.restore_entity: node '%s' has no entity_id." % node.name)
		return

	if _entities.has(eid):
		# We have saved data — restore it onto the freshly spawned node.
		_apply_to_node(node, _entities[eid])
	else:
		# First time we've seen this entity — record its initial state.
		_capture_entity(node)


# Call from an entity's death / permanent-destruction code so it is not
# respawned the next time this scene loads:
#     SceneManager.remove_entity(self)
func remove_entity(node: Node) -> void:
	_entities.erase(_get_id(node))


# ═════════════════════════════════════════════════════════════════════════════
#  PUBLIC API — disk save / load
# ═════════════════════════════════════════════════════════════════════════════

# Write current in-memory state to disk.
# Captures the live scene first so everything is up to date.
func save_to_disk() -> void:
	_capture_all(get_tree())

	var raw_entities := {}
	for eid in _entities:
		raw_entities[eid] = _entities[eid].to_dict()

	var payload := {
		"scene_path": _saved_scene_path,
		"player":     _player_data,
		"entities":   raw_entities,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SceneManager: could not write save file.")
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("SceneManager: saved to disk → ", SAVE_PATH)


# Read state from disk into memory, then travel to the saved scene.
# Returns false if no save file exists.
func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SceneManager: could not read save file.")
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SceneManager: save file is corrupt.")
		return false

	_player_data      = parsed.get("player", _player_data)
	_saved_scene_path = parsed.get("scene_path", "")

	_entities.clear()
	for eid in parsed.get("entities", {}):
		_entities[eid] = EntityData.from_dict(parsed["entities"][eid])

	print("SceneManager: loaded from disk ← ", SAVE_PATH)

	# Travel to the saved scene, which will trigger the auto-restore pass.
	if _saved_scene_path != "":
		_restoring = true
		get_tree().change_scene_to_file(_saved_scene_path)

	return true


# Wipe all in-memory state. Call this for "New Game".
func reset() -> void:
	_player_data = {
		"position_x": 0.0, "position_y": 0.0,
		"health": 100.0,   "max_health": 100.0,
		"inventory": [],   "extra": {},
	}
	_entities.clear()
	_saved_scene_path = ""


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# ═════════════════════════════════════════════════════════════════════════════
#  PRIVATE — capturing state out of the live scene
# ═════════════════════════════════════════════════════════════════════════════

func _capture_all(tree: SceneTree) -> void:
	# Capture the player first.
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		_capture_player(players[0])

	# Capture every tracked entity group.
	for group in ENTITY_GROUPS:
		for node in tree.get_nodes_in_group(group):
			_capture_entity(node)


func _capture_player(node: Node) -> void:
	if node.get("position") != null:
		_player_data["position_x"] = node.position.x
		_player_data["position_y"] = node.position.y
	if node.get("health") != null:
		_player_data["health"] = node.health
	if node.get("max_health") != null:
		_player_data["max_health"] = node.max_health
	if node.has_method("get_inventory_data"):
		_player_data["inventory"] = node.get_inventory_data()
	if node.has_method("get_extra_data"):
		_player_data["extra"] = node.get_extra_data()


func _capture_entity(node: Node) -> void:
	var eid := _get_id(node)
	if eid == "":
		# Skip nodes that have no entity_id — we can't track them reliably.
		return

	# Reuse an existing record so we don't lose fields we can't re-read
	# (e.g. scene_path, which is only knowable at first capture).
	var data: EntityData
	if _entities.has(eid):
		data = _entities[eid]
	else:
		data            = EntityData.new()
		data.entity_id  = eid
		data.scene_path = node.scene_file_path  # empty for editor-placed nodes; that's fine

		# Determine entity type from whichever group this node belongs to.
		for group in ENTITY_GROUPS:
			if node.is_in_group(group):
				data.entity_type = group
				break

	# Refresh all mutable fields every time.
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

	_entities[eid] = data


# ═════════════════════════════════════════════════════════════════════════════
#  PRIVATE — restoring state onto a live scene
# ═════════════════════════════════════════════════════════════════════════════

# Fired for every node added to the SceneTree. We wait for the new scene root,
# which is the direct child of root, then run a full restore pass.
func _on_node_added(node: Node) -> void:
	if not _restoring:
		return
	# The new scene root is a direct child of the tree's root node.
	if node.get_parent() != get_tree().root:
		return
	# Ignore this singleton itself re-entering (shouldn't happen, but be safe).
	if node == self:
		return

	_restoring = false

	# Wait one frame so all editor-placed child nodes of the new scene have
	# finished entering the tree before we try to find them by group.
	await get_tree().process_frame
	_restore_all(get_tree())


func _restore_all(tree: SceneTree) -> void:
	# Restore the player.
	var players := tree.get_nodes_in_group("player")
	if players.size() > 0:
		_restore_player(players[0])

	# Restore all editor-placed entities that are already in the scene.
	for group in ENTITY_GROUPS:
		for node in tree.get_nodes_in_group(group):
			var eid := _get_id(node)
			if _entities.has(eid):
				_apply_to_node(node, _entities[eid])


func _restore_player(node: Node) -> void:
	if node.get("position") != null:
		node.position = Vector2(_player_data["position_x"], _player_data["position_y"])
	if node.get("health") != null:
		node.health = _player_data["health"]
	if node.get("max_health") != null:
		node.max_health = _player_data["max_health"]
	if node.has_method("set_inventory_data") and (_player_data["inventory"] as Array).size() > 0:
		node.set_inventory_data(_player_data["inventory"])
	if node.has_method("set_extra_data") and (_player_data["extra"] as Dictionary).size() > 0:
		node.set_extra_data(_player_data["extra"])


func _apply_to_node(node: Node, data: EntityData) -> void:
	if node.get("position") != null:
		node.position = data.position
	if node.get("health") != null and data.health >= 0.0:
		node.health = data.health
	if node.get("max_health") != null and data.max_health >= 0.0:
		node.max_health = data.max_health
	if node.has_method("set_inventory_data") and data.inventory.size() > 0:
		node.set_inventory_data(data.inventory)
	if node.has_method("set_extra_data") and data.extra.size() > 0:
		node.set_extra_data(data.extra)


# ═════════════════════════════════════════════════════════════════════════════
#  PRIVATE — utility
# ═════════════════════════════════════════════════════════════════════════════

func _get_id(node: Node) -> String:
	var eid = node.get("entity_id")
	if eid != null and (eid as String) != "":
		return eid as String
	return ""
