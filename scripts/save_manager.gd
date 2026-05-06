extends Node

const SAVE_PATH := "user://save.cfg"


func save_meta(xp: int, level: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("meta", "xp", xp)
	cfg.set_value("meta", "level", level)
	cfg.save(SAVE_PATH)


func load_meta() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {"xp": 0, "level": 1}
	return {
		"xp": cfg.get_value("meta", "xp", 0),
		"level": cfg.get_value("meta", "level", 1),
	}


func save_run(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("run", "in_progress", true)
	for key: String in data:
		cfg.set_value("run", key, data[key])
	cfg.save(SAVE_PATH)


func load_run() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	if not cfg.get_value("run", "in_progress", false):
		return {}
	var data: Dictionary = {}
	for key: String in cfg.get_section_keys("run"):
		data[key] = cfg.get_value("run", key)
	return data


func clear_run() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if cfg.has_section("run"):
		cfg.erase_section("run")
	cfg.save(SAVE_PATH)


func has_run() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return cfg.get_value("run", "in_progress", false)


func load_buffs() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {"attack": 0, "block": 0, "hp": 0}
	return {
		"attack": cfg.get_value("buffs", "attack", 0),
		"block": cfg.get_value("buffs", "block", 0),
		"hp": cfg.get_value("buffs", "hp", 0),
		"heal": cfg.get_value("buffs", "heal", 0),
	}


func apply_perm_buff(kind: String, amount: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var current: int = cfg.get_value("buffs", kind, 0)
	cfg.set_value("buffs", kind, current + amount)
	cfg.save(SAVE_PATH)


func unlock_card(card_data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var existing: Array = cfg.get_value("cards", "unlocked", [])
	existing.append(card_data)
	cfg.set_value("cards", "unlocked", existing)
	cfg.save(SAVE_PATH)


func load_unlocked_cards() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return []
	return cfg.get_value("cards", "unlocked", [])


func clear_unlocked_cards() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if cfg.has_section("cards"):
		cfg.erase_section("cards")
	cfg.save(SAVE_PATH)


func save_map_data(node_data: Array, cleared: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("map", "exists", true)
	cfg.set_value("map", "cleared", cleared)
	cfg.set_value("map", "nodes", node_data)
	cfg.save(SAVE_PATH)


func load_map_data() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	if not cfg.get_value("map", "exists", false):
		return {}
	return {
		"nodes": cfg.get_value("map", "nodes", []),
		"cleared": cfg.get_value("map", "cleared", false),
	}


func has_map() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return cfg.get_value("map", "exists", false) and \
		not cfg.get_value("map", "cleared", false)


func clear_map() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	if cfg.has_section("map"):
		cfg.erase_section("map")
	cfg.save(SAVE_PATH)


func clear_all() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
