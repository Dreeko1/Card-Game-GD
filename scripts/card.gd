class_name Card
extends RefCounted

enum Type {
	ATTACK,
	BLOCK,
	HEAL,
	BUFF,
	DEBUFF
}

enum BuffStat { ATTACK, HEAL }

var card_name: String
var description: String
var type: Type
var value: int
var mana_cost: int
var duration: int = 1


func _init(p_name: String, p_type: Type, p_value: int, p_cost: int) -> void:
	card_name = p_name
	type = p_type
	value = p_value
	mana_cost = p_cost
	description = _build_description()


func _build_description() -> String:
	match type:
		Type.ATTACK: return "Infligge %d danni" % value
		Type.BLOCK:  return "Blocca %d danni" % value
		Type.HEAL:   return "Recupera %d HP" % value
		Type.BUFF:   return "+%d danno per 1 turno" % value
		Type.DEBUFF: return "+%d danno subito per 1 turno" % value
	return ""


func _to_string() -> String:
	return "%s (%s) [%d mana]" % [card_name, description, mana_cost]
