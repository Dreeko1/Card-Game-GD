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

static func get_data(type: Type) -> Dictionary:
	return DATA[type]

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
