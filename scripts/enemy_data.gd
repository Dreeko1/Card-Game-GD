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
	return c

static func _build_deck(profile: String) -> Deck:
	var deck := Deck.new()
	deck.cards.clear()
	match profile:
		"goblin":
			_fill(deck, [4,5,4,6,5,4,7,5,6,4], Card.Suit.PICCHE)
		"troll":
			_fill(deck, [7,8,9,8,7,1,2,9,8,7], Card.Suit.PICCHE)
	return deck

static func _fill(deck: Deck, values: Array, suit: Card.Suit) -> void:
	for v in values:
		deck.cards.append(Card.new(v, suit))
