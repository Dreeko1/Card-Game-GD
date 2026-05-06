class_name EnemyData
extends RefCounted

enum Type { GOBLIN, SCHELETRO, BANDITO, ORCO, STREGA, TROLL, DRAGO, LICH }

# difficulty: 1 = facile, 2 = medio, 3 = difficile  (usato dalla futura mappa)
const DATA := {
	Type.GOBLIN: {
		"name": "Goblin",
		"health": 15,
		"initiative": 6,
		"deck_profile": "goblin",
		"difficulty": 1,
	},
	Type.SCHELETRO: {
		"name": "Scheletro",
		"health": 18,
		"initiative": 9,
		"deck_profile": "scheletro",
		"difficulty": 1,
	},
	Type.BANDITO: {
		"name": "Bandito",
		"health": 25,
		"initiative": 12,
		"deck_profile": "bandito",
		"difficulty": 2,
	},
	Type.ORCO: {
		"name": "Orco",
		"health": 32,
		"initiative": 7,
		"deck_profile": "orco",
		"difficulty": 2,
	},
	Type.STREGA: {
		"name": "Strega",
		"health": 22,
		"initiative": 11,
		"deck_profile": "strega",
		"difficulty": 2,
	},
	Type.TROLL: {
		"name": "Troll",
		"health": 45,
		"initiative": 5,
		"deck_profile": "troll",
		"difficulty": 3,
	},
	Type.DRAGO: {
		"name": "Drago Giovane",
		"health": 55,
		"initiative": 8,
		"deck_profile": "drago",
		"difficulty": 3,
	},
	Type.LICH: {
		"name": "Lich",
		"health": 38,
		"initiative": 13,
		"deck_profile": "lich",
		"difficulty": 3,
	},
}

static func enemies_by_difficulty(level: int) -> Array[Type]:
	var result: Array[Type] = []
	for type: Type in DATA:
		if DATA[type]["difficulty"] == level:
			result.append(type)
	return result

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
		"scheletro":
			_add(deck, "Lama Ossea",   Card.Type.ATTACK, 5, 1, 3)
			_add(deck, "Scudo d'Ossa", Card.Type.BLOCK,  4, 1, 2)
			_add(deck, "Maledizione",  Card.Type.DEBUFF, 2, 1, 2)
			_add(deck, "Osso Aguzto",  Card.Type.ATTACK, 3, 1, 3)
		"bandito":
			_add(deck, "Pugnalata",  Card.Type.ATTACK, 7, 1, 3)
			_add(deck, "Veleno",     Card.Type.DEBUFF, 3, 1, 3)
			_add(deck, "Parata",     Card.Type.BLOCK,  5, 1, 2)
			_add(deck, "Scappa!",    Card.Type.HEAL,   4, 2, 1)
		"orco":
			_add(deck, "Ascia",         Card.Type.ATTACK, 9, 2, 3)
			_add(deck, "Furia Orca",    Card.Type.BUFF,   3, 1, 2)
			_add(deck, "Scudo di Cuoio",Card.Type.BLOCK,  6, 2, 2)
			_add(deck, "Schiaccia!",    Card.Type.ATTACK, 7, 2, 3)
		"strega":
			_add(deck, "Incantesimo",   Card.Type.ATTACK, 7, 2, 3)
			_add(deck, "Maledizione",   Card.Type.DEBUFF, 3, 1, 3)
			_add(deck, "Rigenerazione", Card.Type.HEAL,   6, 2, 2)
			_add(deck, "Scudo Arcano",  Card.Type.BLOCK,  5, 2, 1)
		"troll":
			_add(deck, "Mazzata",    Card.Type.ATTACK, 10, 3, 3)
			_add(deck, "Schianto",   Card.Type.ATTACK,  8, 2, 3)
			_add(deck, "Pelle Dura", Card.Type.BLOCK,  10, 2, 2)
			_add(deck, "Ruggito",    Card.Type.DEBUFF,  4, 2, 2)
		"drago":
			_add(deck, "Soffio di Fuoco", Card.Type.ATTACK, 12, 3, 3)
			_add(deck, "Coda Schiaffante",Card.Type.ATTACK,  8, 2, 2)
			_add(deck, "Scaglie",         Card.Type.BLOCK,  12, 2, 2)
			_add(deck, "Ruggito Draconico",Card.Type.DEBUFF, 5, 2, 1)
			_add(deck, "Artigli",         Card.Type.ATTACK,  6, 1, 2)
		"lich":
			_add(deck, "Raggio Oscuro",    Card.Type.ATTACK, 9, 2, 3)
			_add(deck, "Drenaggio Vitale", Card.Type.HEAL,   7, 2, 2)
			_add(deck, "Maledizione Nera", Card.Type.DEBUFF, 5, 2, 3)
			_add(deck, "Muro di Magia",    Card.Type.BLOCK,  8, 3, 1)
			_add(deck, "Freccia d'Ossa",   Card.Type.ATTACK, 6, 1, 2)
	return deck

static func _add(deck: Deck, p_name: String, p_type: Card.Type, p_value: int, p_cost: int, count: int = 1) -> void:
	for i in count:
		deck.cards.append(Card.new(p_name, p_type, p_value, p_cost))
