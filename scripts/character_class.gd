class_name CharacterClass
extends RefCounted

enum Type { GUERRIERO, DRUIDO, MAGO, LADRO }

const DATA := {
	Type.GUERRIERO: {
		"name": "Guerriero",
		"health": 40,
		"initiative": 8,
		"deck_profile": "tank"
	},
	Type.DRUIDO: {
		"name": "Druido",
		"health": 30,
		"initiative": 10,
		"deck_profile": "support"
	},
	Type.MAGO: {
		"name": "Mago",
		"health": 20,
		"initiative": 14,
		"deck_profile": "burst"
	},
	Type.LADRO: {
		"name": "Ladro",
		"health": 28,
		"initiative": 12,
		"deck_profile": "agile"
	}
}

const CLASS_UNLOCK_CARDS := {
	Type.GUERRIERO: {
		1: [
			{"name": "Stoccata",     "type": Card.Type.ATTACK, "value": 10, "mana_cost": 3},
			{"name": "Scudo Totale", "type": Card.Type.BLOCK,  "value": 12, "mana_cost": 3},
		],
		2: [
			{"name": "Grido di Guerra", "type": Card.Type.BUFF, "value": 5, "mana_cost": 2},
			{"name": "Seconda Pelle",   "type": Card.Type.BUFF, "value": 3, "mana_cost": 2},
		],
	},
	Type.DRUIDO: {
		1: [
			{"name": "Radici",       "type": Card.Type.DEBUFF, "value": 4, "mana_cost": 2},
			{"name": "Rigenerazione","type": Card.Type.HEAL,   "value": 8, "mana_cost": 2},
		],
		2: [
			{"name": "Forma Orso",      "type": Card.Type.BUFF,  "value": 4, "mana_cost": 2},
			{"name": "Spore Velenose",  "type": Card.Type.DEBUFF,"value": 6, "mana_cost": 3},
		],
	},
	Type.MAGO: {
		1: [
			{"name": "Palla di Fuoco", "type": Card.Type.ATTACK, "value": 12, "mana_cost": 3},
			{"name": "Fulmine",        "type": Card.Type.ATTACK, "value": 8,  "mana_cost": 2},
		],
		2: [
			{"name": "Amplifica",    "type": Card.Type.BUFF,  "value": 6, "mana_cost": 3},
			{"name": "Scudo Arcano", "type": Card.Type.BLOCK, "value": 8, "mana_cost": 2},
		],
	},
	Type.LADRO: {
		1: [
			{"name": "Pugnalata", "type": Card.Type.ATTACK, "value": 7, "mana_cost": 2},
			{"name": "Fuga",      "type": Card.Type.BLOCK,  "value": 4, "mana_cost": 1},
		],
		2: [
			{"name": "Veleno",       "type": Card.Type.DEBUFF, "value": 5, "mana_cost": 2},
			{"name": "Doppio Taglio","type": Card.Type.ATTACK, "value": 6, "mana_cost": 2},
		],
	},
}

static func get_data(type: Type) -> Dictionary:
	return DATA[type]

static func get_unlock_cards_for_zone(type: Type, zone: int) -> Array:
	var class_zones: Dictionary = CLASS_UNLOCK_CARDS.get(type, {})
	return class_zones.get(zone, [])

static func build_combatant(type: Type) -> Combatant:
	var d: Dictionary = DATA[type]
	var c := Combatant.new(d["name"], d["health"], d["initiative"])
	c.deck_profile = d["deck_profile"]
	c.deck = _build_deck(c.deck_profile)
	c.deck.shuffle()
	c.deck_total = c.deck.remaining()
	return c

static func _build_deck(_profile: String) -> Deck:
	var deck := Deck.new()
	_add(deck, "Colpo",   Card.Type.ATTACK, 5, 1, 2)
	_add(deck, "Difesa",  Card.Type.BLOCK,  5, 1, 2)
	_add(deck, "Pozione", Card.Type.HEAL,   4, 1, 1)
	return deck

static func _add(deck: Deck, p_name: String, p_type: Card.Type, p_value: int, p_cost: int, count: int = 1) -> void:
	for i in count:
		deck.cards.append(Card.new(p_name, p_type, p_value, p_cost))
