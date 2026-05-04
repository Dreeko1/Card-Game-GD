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
	return c

static func _build_deck(profile: String) -> Deck:
	var deck := Deck.new()
	deck.cards.clear()
	match profile:
		"tank":
			_fill(deck, [4,5,6,7,7,8,6,5,4,3], Card.Suit.CUORI)
		"support":
			_fill(deck, [1,2,3,8,9,5,6,1,2,9], Card.Suit.QUADRI)
		"burst":
			_fill(deck, [6,7,8,9,10,7,8,9,10,6], Card.Suit.FIORI)
		"agile":
			_fill(deck, [8,9,10,9,8,5,6,10,9,8], Card.Suit.CUORI)
	return deck

static func _fill(deck: Deck, values: Array, suit: Card.Suit) -> void:
	for v in values:
		deck.cards.append(Card.new(v, suit))
