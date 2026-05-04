class_name Card
extends RefCounted

enum Suit { CUORI, QUADRI, FIORI, PICCHE }

enum EffectType {
	NONE,
	DAMAGE,
	HEAL,
	BUFF,
	DEBUFF
}

const SUIT_NAMES := {
	Suit.CUORI: "Cuori",
	Suit.QUADRI: "Quadri",
	Suit.FIORI: "Fiori",
	Suit.PICCHE: "Picche",
}

const VALUE_NAMES := {
	1: "Asso", 11: "Fante", 12: "Regina", 13: "Re"
}

var card_name: String
var value: int
var suit: Suit
var effect_type: EffectType = EffectType.NONE
var effect_value: int = 0
var effect_stat: String = ""


func _init(p_value: int, p_suit: Suit) -> void:
	value = p_value
	suit = p_suit
	card_name = "%s di %s" % [_value_label(), SUIT_NAMES[suit]]
	_assign_effect()


func _assign_effect() -> void:
	if value <= 3:
		effect_type = EffectType.HEAL
		effect_value = value * 2
	elif value <= 7:
		effect_type = EffectType.DAMAGE
		effect_value = value
	elif value <= 9:
		effect_type = EffectType.DEBUFF
		effect_value = value - 5
		effect_stat = "initiative"
	else:
		effect_type = EffectType.BUFF
		effect_value = value - 7
		effect_stat = "initiative"


func description() -> String:
	match effect_type:
		EffectType.DAMAGE: return "Danno: %d" % effect_value
		EffectType.HEAL:   return "Cura: %d HP" % effect_value
		EffectType.BUFF:   return "Buff %s: +%d" % [effect_stat, effect_value]
		EffectType.DEBUFF: return "Debuff %s: -%d" % [effect_stat, effect_value]
	return "Nessun effetto"


func _value_label() -> String:
	return VALUE_NAMES.get(value, str(value))


func _to_string() -> String:
	return "%s (%s)" % [card_name, description()]
