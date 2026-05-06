extends Control

@onready var deck_container: VBoxContainer = $ScrollContainer/MarginContainer/ContentBox/DeckContainer
@onready var buffs_label: Label = $ScrollContainer/MarginContainer/ContentBox/BuffsLabel


func _ready() -> void:
	$BackButton.pressed.connect(_on_back)
	_populate_buffs()
	_populate_deck()


func _populate_buffs() -> void:
	var buffs := SaveManager.load_buffs()
	var atk: int = buffs.get("attack", 0)
	var blk: int = buffs.get("block", 0)
	var hp: int = buffs.get("hp", 0)
	var lines := []
	if atk > 0:
		lines.append("⚔  +%d Attacco permanente" % atk)
	if blk > 0:
		lines.append("🛡  +%d Difesa permanente" % blk)
	if hp > 0:
		lines.append("❤  +%d HP massimi" % hp)
	if lines.is_empty():
		buffs_label.text = "Nessun buff attivo."
	else:
		buffs_label.text = "\n".join(lines)


func _populate_deck() -> void:
	var base_cards := [
		{"name": "Colpo",   "type": "Attacco",      "mana": 1},
		{"name": "Difesa",  "type": "Difesa",        "mana": 1},
		{"name": "Pozione", "type": "Cura",          "mana": 1},
	]
	for c in base_cards:
		_add_card_row(c.name, c.type, c.mana, false)

	var unlocked := SaveManager.load_unlocked_cards()
	for card_data in unlocked:
		var type_name := _type_label(card_data.get("type", 0) as Card.Type)
		_add_card_row(card_data.get("name", "?"), type_name, card_data.get("mana_cost", 1), true)


func _add_card_row(card_name: String, type_name: String, mana: int, is_unlocked: bool) -> void:
	var lbl := Label.new()
	var prefix := "★ " if is_unlocked else "  "
	lbl.text = "%s%s  [%s — %d mana]" % [prefix, card_name, type_name, mana]
	deck_container.add_child(lbl)


func _type_label(type: Card.Type) -> String:
	match type:
		Card.Type.ATTACK: return "Attacco"
		Card.Type.BLOCK:  return "Difesa"
		Card.Type.HEAL:   return "Cura"
		Card.Type.BUFF:   return "Potenziamento"
		Card.Type.DEBUFF: return "Indebolimento"
	return "?"


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")
