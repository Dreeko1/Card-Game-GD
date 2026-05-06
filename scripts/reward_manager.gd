extends Node

const TYPE_CARD := "card"
const TYPE_BUFF := "buff"

const CARD_POOL: Array[Dictionary] = [
	{"name": "Colpo Pesante", "type": Card.Type.ATTACK, "value": 8, "mana_cost": 2},
	{"name": "Furia",         "type": Card.Type.ATTACK, "value": 6, "mana_cost": 1},
	{"name": "Stoccata",      "type": Card.Type.ATTACK, "value": 10, "mana_cost": 3},
	{"name": "Corazza",       "type": Card.Type.BLOCK,  "value": 8, "mana_cost": 2},
	{"name": "Scudo d'Acciaio","type": Card.Type.BLOCK, "value": 6, "mana_cost": 1},
	{"name": "Rigenerazione", "type": Card.Type.HEAL,   "value": 8, "mana_cost": 2},
	{"name": "Furore",        "type": Card.Type.BUFF,   "value": 3, "mana_cost": 1},
	{"name": "Maledizione",   "type": Card.Type.DEBUFF, "value": 4, "mana_cost": 2},
]

const BUFF_POOL: Array[Dictionary] = [
	{"kind": "attack", "amount": 2, "label": "+2 Attacco permanente"},
	{"kind": "block",  "amount": 2, "label": "+2 Difesa permanente"},
	{"kind": "hp",     "amount": 5, "label": "+5 HP massimi"},
]


func generate_rewards(count: int) -> Array:
	var all_options: Array = []
	for card_data in CARD_POOL:
		all_options.append({"reward_type": TYPE_CARD, "data": card_data})
	for buff_data in BUFF_POOL:
		all_options.append({"reward_type": TYPE_BUFF, "data": buff_data})
	all_options.shuffle()

	# Garantisce almeno 1 carta e 1 buff tra le opzioni
	var result: Array = []
	var has_card := false
	var has_buff := false
	for option in all_options:
		if result.size() >= count:
			break
		if option.reward_type == TYPE_CARD and not has_card:
			result.append(option)
			has_card = true
		elif option.reward_type == TYPE_BUFF and not has_buff:
			result.append(option)
			has_buff = true

	for option in all_options:
		if result.size() >= count:
			break
		if not result.has(option):
			result.append(option)

	result.shuffle()
	return result


func apply_reward(option: Dictionary) -> void:
	if option.reward_type == TYPE_CARD:
		var d: Dictionary = option.data
		SaveManager.unlock_card({
			"name": d.name,
			"type": int(d.type),
			"value": d.value,
			"mana_cost": d.mana_cost,
		})
	elif option.reward_type == TYPE_BUFF:
		SaveManager.apply_perm_buff(option.data.kind, option.data.amount)


func reward_display_text(option: Dictionary) -> String:
	if option.reward_type == TYPE_CARD:
		var d: Dictionary = option.data
		var type_name := _type_label(d.type)
		return "Carta: %s\n%s — %d mana" % [d.name, type_name, d.mana_cost]
	elif option.reward_type == TYPE_BUFF:
		return "Buff permanente\n%s" % option.data.label
	return ""


func _type_label(type: Card.Type) -> String:
	match type:
		Card.Type.ATTACK: return "Attacco"
		Card.Type.BLOCK:  return "Difesa"
		Card.Type.HEAL:   return "Cura"
		Card.Type.BUFF:   return "Potenziamento"
		Card.Type.DEBUFF: return "Indebolimento"
	return ""
