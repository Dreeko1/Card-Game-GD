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

const ENEMY_TURN_DELAY := 0.6
const HAND_SIZE := 3

var current_state: State = State.IDLE
var player: Combatant
var enemy: Combatant
var current_turn: int = 0
var turn_order: Array[Combatant] = []
var player_class: CharacterClass.Type
var enemy_type: EnemyData.Type


func _ready() -> void:
	# Niente auto-start: la partita parte da Main quando il giocatore sceglie la classe.
	pass


func new_game(type: CharacterClass.Type = CharacterClass.Type.GUERRIERO, e_type: EnemyData.Type = EnemyData.Type.GOBLIN) -> void:
	player_class = type
	enemy_type = e_type
	player = CharacterClass.build_combatant(type)
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
		_begin_turn()
		return
	var combatant: Combatant = turn_order[index]
	if not combatant.is_alive():
		_process_combatant(index + 1)
		return
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


func play_player_card(card: Card) -> void:
	if current_state != State.PLAYING:
		return
	if player == null or not player.hand.has(card):
		return
	var index: int = turn_order.find(player)
	if index == -1:
		return
	_resolve_card_play(player, card, index)


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
	else:
		combatant.deck = EnemyData._build_deck(combatant.deck_profile)
	combatant.deck.shuffle()
	combat_log.emit("%s rimescola il mazzo!" % combatant.combatant_name)


func _cpu_choose_card(combatant: Combatant) -> Card:
	var hp_percent: float = float(combatant.health) / float(combatant.max_health)
	if combatant.combatant_name == "Troll" and hp_percent < 0.4:
		for card in combatant.hand:
			if card.effect_type == Card.EffectType.HEAL or card.effect_type == Card.EffectType.BUFF:
				return card
	var best: Card = combatant.hand[0]
	for card in combatant.hand:
		if card.effect_type == Card.EffectType.DAMAGE and card.effect_value > best.effect_value:
			best = card
	return best


func _apply_card(user: Combatant, target: Combatant, card: Card) -> void:
	match card.effect_type:
		Card.EffectType.DAMAGE:
			apply_damage(user, target, card.effect_value)
		Card.EffectType.HEAL:
			var before: int = user.health
			user.heal(card.effect_value)
			var actual: int = user.health - before
			if actual > 0:
				healed.emit(user, actual)
			combat_log.emit("%s si cura di %d HP (HP: %d/%d)" % [user.combatant_name, card.effect_value, user.health, user.max_health])
		Card.EffectType.BUFF:
			user.initiative += card.effect_value
			combat_log.emit("%s ottiene +%d iniziativa" % [user.combatant_name, card.effect_value])
		Card.EffectType.DEBUFF:
			target.initiative = max(1, target.initiative - card.effect_value)
			combat_log.emit("%s perde %d iniziativa" % [target.combatant_name, card.effect_value])


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


func _set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(current_state)
