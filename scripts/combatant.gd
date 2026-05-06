class_name Combatant
extends RefCounted

var combatant_name: String
var max_health: int
var health: int
var initiative: int
var deck: Deck
var deck_total: int = 0
var deck_profile: String = ""
var hand: Array[Card] = []
var mana: int = 0
var max_mana: int = 0
var attack_bonus: int = 0
var block_buffer: int = 0
var damage_taken_bonus: int = 0
var perm_attack_bonus: int = 0
var perm_block_bonus: int = 0


func _init(p_name: String, p_max_health: int, p_initiative: int) -> void:
	combatant_name = p_name
	max_health = p_max_health
	health = p_max_health
	initiative = p_initiative


func is_alive() -> bool:
	return health > 0


func take_damage(amount: int) -> void:
	health = max(0, health - amount)


func heal(amount: int) -> void:
	health = min(max_health, health + amount)


func draw_card() -> Card:
	if deck == null or deck.is_empty():
		return null
	var card := deck.draw()
	if card:
		hand.append(card)
	return card


func start_turn(turn_number: int) -> void:
	max_mana = min(turn_number, 10)
	mana = max_mana
	block_buffer = 0


func status() -> String:
	return "%s — HP: %d/%d  |  Iniziativa: %d" % [combatant_name, health, max_health, initiative]
