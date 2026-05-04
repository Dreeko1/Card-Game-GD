class_name Deck
extends RefCounted

# Mazzo da 30 carte: valori 1–10 per 3 semi (Cuori, Quadri, Fiori)
const VALUES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const SUITS  := [Card.Suit.CUORI, Card.Suit.QUADRI, Card.Suit.FIORI]

var cards: Array[Card] = []


func _init() -> void:
	_build()


func _build() -> void:
	cards.clear()
	for suit in SUITS:
		for v in VALUES:
			cards.append(Card.new(v, suit))
	# 3 semi × 10 valori = 30 carte


func shuffle() -> void:
	cards.shuffle()


func draw() -> Card:
	if cards.is_empty():
		return null
	return cards.pop_back()


func remaining() -> int:
	return cards.size()


func is_empty() -> bool:
	return cards.is_empty()
