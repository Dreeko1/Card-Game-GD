class_name Deck
extends RefCounted

var cards: Array[Card] = []


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


func add_card(card: Card) -> void:
	cards.append(card)
