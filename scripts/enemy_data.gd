class_name EnemyData
extends RefCounted

enum Type { GOBLIN, TROLL }

const DATA := {
	Type.GOBLIN: {
		"name": "Goblin",
		"health": 15,
		"initiative": 6,
		"deck_profile": "goblin"
	},
	Type.TROLL: {
		"name": "Troll",
		"health": 45,
		"initiative": 5,
		"deck_profile": "troll"
	}
}

static func build_combatant(type: Type) -> Combatant:
	var d: Dictionary = DATA[type]
	var c := Combatant.new(d["name"], d["health"], d["initiative"])
	c.deck_profile = d["deck_profile"]
	c.deck = _build_deck(c.deck_profile)
	c.deck.shuffle()
	c.deck_total = c.deck.remaining()
	return c

static func _build_deck(profile: String) -> Deck:
	var deck := Deck.new()
	match profile:
		"goblin":
			_add(deck, "Graffiata", Card.Type.ATTACK, 4, 1, 4)
			_add(deck, "Morso",     Card.Type.ATTACK, 6, 2, 3)
			_add(deck, "Urlo",      Card.Type.DEBUFF, 2, 1, 2)
			_add(deck, "Fuga",      Card.Type.BLOCK,  3, 1, 1)
		"troll":
			_add(deck, "Mazzata",    Card.Type.ATTACK, 10, 3, 3)
			_add(deck, "Schianto",   Card.Type.ATTACK,  8, 2, 3)
			_add(deck, "Pelle Dura", Card.Type.BLOCK,  10, 2, 2)
			_add(deck, "Ruggito",    Card.Type.DEBUFF,  4, 2, 2)
	return deck

static func _add(deck: Deck, p_name: String, p_type: Card.Type, p_value: int, p_cost: int, count: int = 1) -> void:
	for i in count:
		deck.cards.append(Card.new(p_name, p_type, p_value, p_cost))
