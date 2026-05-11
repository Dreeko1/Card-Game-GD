extends Node

enum State { IDLE, PLAYING, GAME_OVER }

signal state_changed(new_state: State)
signal card_drawn(who: Combatant, card: Card)
signal deck_empty(who: Combatant)
signal combat_ended(winner: Combatant)
signal combat_log(message: String)
signal player_turn_started()
signal turn_started(combatant: Combatant)
signal card_played(combatant: Combatant, card: Card)
signal damage_dealt(target: Combatant, amount: int)
signal healed(combatant: Combatant, amount: int)
signal xp_gained(xp_amount: int, leveled_up: bool, new_level: int)

const ENEMY_TURN_DELAY := 0.6
const HAND_SIZE := 3
const MAX_LEVEL := 10
const XP_REWARDS: Dictionary = {
	EnemyData.Type.GOBLIN:    50,
	EnemyData.Type.SCHELETRO: 60,
	EnemyData.Type.BANDITO:   75,
	EnemyData.Type.ORCO:     100,
	EnemyData.Type.STREGA:    90,
	EnemyData.Type.TROLL:    150,
	EnemyData.Type.DRAGO:    200,
	EnemyData.Type.LICH:     220,
}

var current_state: State = State.IDLE
var player: Combatant
var enemy: Combatant
var run_reward_cards: Array[Dictionary] = []
var current_turn: int = 0
var turn_order: Array[Combatant] = []
var player_class: CharacterClass.Type
var enemy_type: EnemyData.Type
var player_level: int = 1
var player_xp: int = 0
var pending_resume: bool = false
var map_mode: bool = false
var pending_combat: bool = false
var map_enemy_type: EnemyData.Type = EnemyData.Type.GOBLIN
var map_current_node_id: int = -1


func _ready() -> void:
	var meta := SaveManager.load_meta()
	player_xp = meta.xp
	player_level = meta.level


func new_game(type: CharacterClass.Type = CharacterClass.Type.GUERRIERO, e_type: EnemyData.Type = EnemyData.Type.GOBLIN) -> void:
	player_class = type
	enemy_type = e_type
	if not map_mode:
		run_reward_cards = []
	player = CharacterClass.build_combatant(type)
	_apply_meta_to_player(true)
	enemy = EnemyData.build_combatant(e_type)

	_set_state(State.PLAYING)
	_print_status()
	# Le mani vengono riempite a inizio turno da _ensure_hand (cap = HAND_SIZE).
	start_combat()


func draw_card_for(combatant: Combatant) -> Card:
	if current_state != State.PLAYING:
		return null

	var card := combatant.draw_card()
	if card == null:
		deck_empty.emit(combatant)
		return null

	card_drawn.emit(combatant, card)
	return card


func apply_damage(attacker: Combatant, target: Combatant, amount: int) -> void:
	var before: int = target.health
	target.take_damage(amount)
	var actual: int = before - target.health
	damage_dealt.emit(target, actual)
	combat_log.emit("%s colpisce %s per %d danni! (HP rimanenti: %d/%d)" % [
		attacker.combatant_name, target.combatant_name,
		amount, target.health, target.max_health
	])

	if not target.is_alive():
		combat_log.emit("%s è stato sconfitto! Vince %s!" % [target.combatant_name, attacker.combatant_name])
		if attacker == player:
			_award_xp()
		SaveManager.clear_run()
		combat_ended.emit(attacker)
		_set_state(State.GAME_OVER)


func start_combat() -> void:
	current_turn = 0
	turn_order = [player, enemy]
	turn_order.sort_custom(func(a, b): return a.initiative > b.initiative)
	combat_log.emit("\n=== INIZIO COMBATTIMENTO ===")
	combat_log.emit("Ordine di turno: %s → %s" % [turn_order[0].combatant_name, turn_order[1].combatant_name])
	_begin_turn()


func _begin_turn() -> void:
	if current_state != State.PLAYING:
		return
	if not player.is_alive() or not enemy.is_alive():
		return
	current_turn += 1
	combat_log.emit("\n--- Turno %d ---" % current_turn)
	_process_combatant(0)


func _process_combatant(index: int) -> void:
	if current_state != State.PLAYING:
		return
	if index >= turn_order.size():
		_end_turn()
		_begin_turn()
		return
	var combatant: Combatant = turn_order[index]
	if not combatant.is_alive():
		_process_combatant(index + 1)
		return
	combatant.start_turn(current_turn)
	_ensure_hand(combatant)
	if combatant.hand.is_empty():
		_process_combatant(index + 1)
		return
	turn_started.emit(combatant)
	if combatant == player:
		# Aspettiamo l'input del giocatore: la UI riprenderà chiamando play_player_card()
		player_turn_started.emit()
	else:
		var card: Card = _cpu_choose_card(combatant)
		await get_tree().create_timer(ENEMY_TURN_DELAY).timeout
		# Se nel frattempo il combattimento è finito, abortiamo
		if current_state != State.PLAYING:
			return
		_resolve_card_play(combatant, card, index)


func skip_player_turn() -> void:
	if current_state != State.PLAYING:
		return
	combat_log.emit("%s passa il turno." % player.combatant_name)
	_finish_player_turn()


func play_player_card(card: Card) -> void:
	if current_state != State.PLAYING:
		return
	if player == null or not player.hand.has(card):
		return
	if player.mana < card.mana_cost:
		combat_log.emit("Mana insufficiente per %s! (%d/%d mana)" % [card.card_name, player.mana, card.mana_cost])
		player_turn_started.emit()
		return
	player.hand.erase(card)
	combat_log.emit("%s gioca: %s" % [player.combatant_name, str(card)])
	card_played.emit(player, card)
	_apply_card(player, enemy, card)
	if current_state != State.PLAYING:
		return
	if _player_has_playable_card():
		player_turn_started.emit()
	else:
		_finish_player_turn()


func _player_has_playable_card() -> bool:
	for card in player.hand:
		if player.mana >= card.mana_cost:
			return true
	return false


func _finish_player_turn() -> void:
	_process_combatant(turn_order.find(player) + 1)


func _resolve_card_play(combatant: Combatant, card: Card, index: int) -> void:
	combatant.hand.erase(card)
	var target: Combatant = enemy if combatant == player else player
	combat_log.emit("%s gioca: %s" % [combatant.combatant_name, str(card)])
	card_played.emit(combatant, card)
	_apply_card(combatant, target, card)
	if current_state != State.PLAYING:
		return
	_process_combatant(index + 1)


func _ensure_hand(combatant: Combatant) -> void:
	# Pesca fino ad avere HAND_SIZE carte. Se il mazzo finisce durante il refill,
	# viene rimescolato e si continua a pescare fino al raggiungimento del cap.
	while combatant.hand.size() < HAND_SIZE:
		if combatant.deck == null or combatant.deck.is_empty():
			_reshuffle_deck(combatant)
			# Sicurezza: se per qualche motivo il rebuild non ha prodotto carte, esci
			if combatant.deck == null or combatant.deck.is_empty():
				break
		draw_card_for(combatant)


func _reshuffle_deck(combatant: Combatant) -> void:
	if combatant == player:
		combatant.deck = CharacterClass._build_deck(combatant.deck_profile)
		for card_data in run_reward_cards:
			combatant.deck.add_card(Card.new(
				card_data["name"],
				card_data["type"] as Card.Type,
				card_data["value"],
				card_data["mana_cost"]
			))
		var hand_names := combatant.hand.map(func(c: Card) -> String: return c.card_name)
		var deck_names := combatant.deck.cards.map(func(c: Card) -> String: return c.card_name)
		print("[RESHUFFLE] mazzo: %d %s | mano: %d %s" % [
			combatant.deck.cards.size(), deck_names,
			combatant.hand.size(), hand_names,
		])
	else:
		combatant.deck = EnemyData._build_deck(combatant.deck_profile)
	combatant.deck.shuffle()
	combat_log.emit("%s rimescola il mazzo!" % combatant.combatant_name)


func _cpu_choose_card(combatant: Combatant) -> Card:
	var hp_percent: float = float(combatant.health) / float(combatant.max_health)
	if hp_percent < 0.4:
		for card in combatant.hand:
			if card.type == Card.Type.HEAL or card.type == Card.Type.BLOCK:
				return card
	var best: Card = combatant.hand[0]
	for card in combatant.hand:
		if card.type == Card.Type.ATTACK and card.value > best.value:
			best = card
	return best


func _apply_card(user: Combatant, target: Combatant, card: Card) -> void:
	user.mana -= card.mana_cost
	match card.type:
		Card.Type.ATTACK:
			var total_damage: int = card.value + user.attack_bonus + user.perm_attack_bonus + target.damage_taken_bonus
			var absorbed: int = target.block_buffer
			var final_damage: int = max(0, total_damage - absorbed)
			target.block_buffer = max(0, absorbed - total_damage)
			if final_damage > 0:
				apply_damage(user, target, final_damage)
			else:
				combat_log.emit("%s assorbe tutto il danno!" % target.combatant_name)
		Card.Type.BLOCK:
			user.block_buffer += card.value + user.perm_block_bonus
			combat_log.emit("%s si difende! (Blocco: %d)" % [user.combatant_name, user.block_buffer])
		Card.Type.HEAL:
			var before: int = user.health
			user.heal(card.value + user.perm_heal_bonus)
			var actual: int = user.health - before
			if actual > 0:
				healed.emit(user, actual)
			combat_log.emit("%s si cura di %d HP! (HP: %d/%d)" % [user.combatant_name, card.value, user.health, user.max_health])
		Card.Type.BUFF:
			user.attack_bonus += card.value
			combat_log.emit("%s potenzia l'attacco di +%d per 1 turno!" % [user.combatant_name, card.value])
		Card.Type.DEBUFF:
			target.damage_taken_bonus += card.value
			print("[DEBUFF] %s usa %s → %s.damage_taken_bonus = %d" % [
				user.combatant_name, card.card_name,
				target.combatant_name, target.damage_taken_bonus
			])
			combat_log.emit("%s indebolisce %s di %d!" % [user.combatant_name, target.combatant_name, card.value])


func _end_turn() -> void:
	player.attack_bonus = 0
	player.damage_taken_bonus = 0
	enemy.attack_bonus = 0
	enemy.damage_taken_bonus = 0


func get_first_attacker() -> Combatant:
	# Chi ha iniziativa più alta attacca per primo; parità → giocatore
	if enemy.initiative > player.initiative:
		return enemy
	return player


func _print_status() -> void:
	print("=== NUOVA PARTITA ===")
	print(player.status())
	print(enemy.status())
	print("====================")


func _award_xp() -> void:
	var reward: int = XP_REWARDS.get(enemy_type, 50)
	player_xp += reward
	var leveled_up := false
	while player_level < MAX_LEVEL and player_xp >= player_level * 100:
		player_level += 1
		leveled_up = true
		combat_log.emit("⬆ LIVELLO SU! Ora sei Livello %d!" % player_level)
	SaveManager.save_meta(player_xp, player_level)
	xp_gained.emit(reward, leveled_up, player_level)


func save_game() -> void:
	SaveManager.save_meta(player_xp, player_level)
	if current_state == State.PLAYING and player != null and enemy != null:
		SaveManager.save_run({
			"player_class": int(player_class),
			"player_hp": player.health,
			"enemy_type": int(enemy_type),
			"enemy_hp": enemy.health,
			"turn": current_turn,
			"map_mode": map_mode,
			"map_current_node_id": map_current_node_id,
			"reward_cards": run_reward_cards,
		})


func load_game() -> void:
	var data := SaveManager.load_run()
	if data.is_empty():
		return
	player_class = data.get("player_class", CharacterClass.Type.GUERRIERO)
	enemy_type = data.get("enemy_type", EnemyData.Type.GOBLIN)
	map_mode = data.get("map_mode", false)
	map_current_node_id = data.get("map_current_node_id", -1)
	run_reward_cards = data.get("reward_cards", [])
	player = CharacterClass.build_combatant(player_class)
	_apply_meta_to_player(false)
	player.health = data.get("player_hp", player.max_health)
	enemy = EnemyData.build_combatant(enemy_type)
	enemy.health = data.get("enemy_hp", enemy.max_health)
	_set_state(State.PLAYING)
	_print_status()
	start_combat()


func _apply_meta_to_player(reset_hp: bool) -> void:
	var buffs := SaveManager.load_buffs()
	player.perm_attack_bonus = buffs.get("attack", 0)
	player.perm_block_bonus = buffs.get("block", 0)
	player.perm_heal_bonus = buffs.get("heal", 0)
	player.max_health += buffs.get("hp", 0)
	if reset_hp:
		player.health = player.max_health
	_add_unlocked_cards_to(player)
	player.deck_total = player.deck.cards.size() + player.hand.size()


func _add_unlocked_cards_to(combatant: Combatant) -> void:
	for card_data in run_reward_cards:
		var c := Card.new(
			card_data["name"],
			card_data["type"] as Card.Type,
			card_data["value"],
			card_data["mana_cost"]
		)
		combatant.deck.add_card(c)
	combatant.deck.shuffle()


func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(current_state)
