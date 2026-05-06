extends Node

const CardTileScene := preload("res://scenes/Cardtile.tscn")

@onready var class_selection: VBoxContainer = $ClassSelection
@onready var game_ui: Control = $GameUI
@onready var player_stats_panel: VBoxContainer = $GameUI/StatsBar/PlayerStats
@onready var enemy_stats_panel: VBoxContainer = $GameUI/StatsBar/EnemyStats
@onready var player_name_label: Label = $GameUI/StatsBar/PlayerStats/player_name
@onready var player_hp_label: Label = $GameUI/StatsBar/PlayerStats/player_hp
@onready var player_block_label: Label = $GameUI/StatsBar/PlayerStats/player_block
@onready var player_initiative_label: Label = $GameUI/StatsBar/PlayerStats/player_initiative
@onready var enemy_name_label: Label = $GameUI/StatsBar/EnemyStats/enemy_name
@onready var enemy_hp_label: Label = $GameUI/StatsBar/EnemyStats/enemy_hp
@onready var enemy_block_label: Label = $GameUI/StatsBar/EnemyStats/enemy_block
@onready var enemy_initiative_label: Label = $GameUI/StatsBar/EnemyStats/enemy_initiative
@onready var combat_log_text: RichTextLabel = $GameUI/MainArea/CombatLog
@onready var enemy_card_played: Label = $GameUI/MainArea/Board/EnemyCardPlayed
@onready var player_card_played: Label = $GameUI/MainArea/Board/PlayerCardPlayed
@onready var player_hand_container: HBoxContainer = $GameUI/PlayerHand
@onready var game_over_overlay: ColorRect = $GameUI/GameOverOverlay
@onready var result_label: Label = $GameUI/GameOverOverlay/Panel/Margin/VBox/ResultLabel
@onready var winner_label: Label = $GameUI/GameOverOverlay/Panel/Margin/VBox/WinnerLabel
@onready var restart_button: Button = $GameUI/GameOverOverlay/Panel/Margin/VBox/RestartButton

var end_turn_button: Button
var player_deck_label: Label
var player_xp_label: Label
var save_button: Button

var _last_xp_gain: int = 0
var _last_leveled_up: bool = false
var _last_new_level: int = 1

const FLASH_DURATION := 0.35
const FLOAT_DURATION := 0.9
const FLOAT_DISTANCE := 50.0
const COLOR_DAMAGE := Color(1.0, 0.35, 0.35)
const COLOR_HEAL   := Color(0.45, 1.0, 0.55)
const COLOR_NAME_ACTIVE   := Color(1.0, 0.92, 0.45)
const COLOR_NAME_INACTIVE := Color(0.92, 0.92, 0.94)


func _ready() -> void:
	GameManager.combat_ended.connect(_on_combat_ended)
	GameManager.combat_log.connect(_on_combat_log)
	GameManager.player_turn_started.connect(_on_player_turn_started)
	GameManager.card_played.connect(_on_card_played)
	GameManager.turn_started.connect(_on_turn_started)
	GameManager.damage_dealt.connect(_on_damage_dealt)
	GameManager.healed.connect(_on_healed)
	GameManager.card_drawn.connect(_on_card_drawn)
	GameManager.xp_gained.connect(_on_xp_gained)
	$ClassSelection/Button_Guerriero.pressed.connect(_select_class.bind(CharacterClass.Type.GUERRIERO))
	$ClassSelection/Button_Druido.pressed.connect(_select_class.bind(CharacterClass.Type.DRUIDO))
	$ClassSelection/Button_Mago.pressed.connect(_select_class.bind(CharacterClass.Type.MAGO))
	$ClassSelection/Button_Ladro.pressed.connect(_select_class.bind(CharacterClass.Type.LADRO))
	restart_button.text = "Menu Principale"
	restart_button.pressed.connect(_on_restart_pressed)
	_create_end_turn_button()
	player_deck_label = Label.new()
	player_stats_panel.add_child(player_deck_label)
	player_xp_label = Label.new()
	player_stats_panel.add_child(player_xp_label)
	_create_save_button()

	if GameManager.map_mode and GameManager.pending_combat:
		GameManager.pending_combat = false
		class_selection.visible = false
		game_ui.visible = true
		_clear_player_hand()
		_reset_visual_state()
		GameManager.new_game(GameManager.player_class, GameManager.map_enemy_type)
	elif GameManager.pending_resume:
		GameManager.pending_resume = false
		if SaveManager.has_map():
			MapManager.load_map()
		class_selection.visible = false
		game_ui.visible = true
		GameManager.load_game()
		_update_stats()


func _create_end_turn_button() -> void:
	end_turn_button = Button.new()
	end_turn_button.text = "Fine Turno"
	end_turn_button.visible = false
	end_turn_button.custom_minimum_size = Vector2(140, 36)
	end_turn_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	player_hand_container.add_child(end_turn_button)
	end_turn_button.pressed.connect(_on_end_turn_pressed)


func _create_save_button() -> void:
	save_button = Button.new()
	save_button.text = "Salva"
	save_button.custom_minimum_size = Vector2(80, 28)
	save_button.visible = false
	player_stats_panel.add_child(save_button)
	save_button.pressed.connect(_on_save_pressed)


func _on_save_pressed() -> void:
	GameManager.save_game()
	save_button.text = "Salvato!"
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		if is_instance_valid(save_button):
			save_button.text = "Salva"
	)


func _on_restart_pressed() -> void:
	if _last_xp_gain > 0:
		get_tree().change_scene_to_file("res://scenes/reward_screen.tscn")
	else:
		if GameManager.map_mode:
			GameManager.map_mode = false
			SaveManager.clear_map()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _select_class(type: CharacterClass.Type) -> void:
	if GameManager.map_mode:
		GameManager.player_class = type
		MapManager.generate_new_map()
		get_tree().change_scene_to_file("res://scenes/world_map.tscn")
		return
	class_selection.visible = false
	game_ui.visible = true
	var random_enemy: EnemyData.Type = EnemyData.Type.values().pick_random()
	_clear_player_hand()
	_reset_visual_state()
	GameManager.new_game(type, random_enemy)


func _reset_visual_state() -> void:
	game_over_overlay.visible = false
	game_over_overlay.modulate.a = 1.0
	combat_log_text.clear()
	enemy_card_played.text = "Nemico: —"
	player_card_played.text = "Giocatore: —"
	player_name_label.remove_theme_color_override("font_color")
	enemy_name_label.remove_theme_color_override("font_color")
	end_turn_button.visible = false
	save_button.visible = false
	save_button.text = "Salva"
	_last_xp_gain = 0
	_last_leveled_up = false


func _update_stats() -> void:
	if GameManager.player == null or GameManager.enemy == null:
		return
	var p := GameManager.player
	var e := GameManager.enemy
	player_name_label.text = p.combatant_name
	player_hp_label.text = "HP: %d/%d" % [p.health, p.max_health]
	player_block_label.text = "🛡 %d" % p.block_buffer
	player_block_label.visible = p.block_buffer > 0
	player_initiative_label.text = "Iniziativa: %d  |  Mana: %d/%d" % [p.initiative, p.mana, p.max_mana]
	player_deck_label.text = "Mazzo: %d/%d" % [p.deck.remaining(), p.deck_total]
	_update_xp_label()
	enemy_name_label.text = e.combatant_name
	enemy_hp_label.text = "HP: %d/%d" % [e.health, e.max_health]
	enemy_block_label.text = "🛡 %d" % e.block_buffer
	enemy_block_label.visible = e.block_buffer > 0
	enemy_initiative_label.text = "Iniziativa: %d" % e.initiative


func _update_xp_label() -> void:
	if GameManager.player_level >= GameManager.MAX_LEVEL:
		player_xp_label.text = "Lv.MAX  |  %d XP" % GameManager.player_xp
	else:
		var xp_in_level := GameManager.player_xp - (GameManager.player_level - 1) * 100
		player_xp_label.text = "Lv.%d  |  %d/100 XP" % [GameManager.player_level, xp_in_level]


func _on_combat_log(message: String) -> void:
	combat_log_text.append_text(message + "\n")
	_update_stats()


func _on_card_played(combatant: Combatant, card: Card) -> void:
	if GameManager.player != null and combatant == GameManager.player:
		player_card_played.text = "Giocatore: %s" % str(card)
	else:
		enemy_card_played.text = "Nemico: %s" % str(card)


func _on_turn_started(combatant: Combatant) -> void:
	_update_stats()
	var is_player_turn: bool = GameManager.player != null and combatant == GameManager.player
	player_name_label.add_theme_color_override(
		"font_color",
		COLOR_NAME_ACTIVE if is_player_turn else COLOR_NAME_INACTIVE
	)
	enemy_name_label.add_theme_color_override(
		"font_color",
		COLOR_NAME_INACTIVE if is_player_turn else COLOR_NAME_ACTIVE
	)


func _on_damage_dealt(target: Combatant, amount: int) -> void:
	if amount <= 0:
		return
	var hp_label: Label = _hp_label_for(target)
	var panel: Control = _stats_panel_for(target)
	if hp_label:
		_flash_label(hp_label, COLOR_DAMAGE)
	if panel:
		_spawn_floating_text(panel, "-%d" % amount, COLOR_DAMAGE)


func _on_healed(combatant: Combatant, amount: int) -> void:
	if amount <= 0:
		return
	var hp_label: Label = _hp_label_for(combatant)
	var panel: Control = _stats_panel_for(combatant)
	if hp_label:
		_flash_label(hp_label, COLOR_HEAL)
	if panel:
		_spawn_floating_text(panel, "+%d" % amount, COLOR_HEAL)


func _on_card_drawn(who: Combatant, _card: Card) -> void:
	if GameManager.player != null and who == GameManager.player:
		_update_stats()


func _hp_label_for(combatant: Combatant) -> Label:
	if GameManager.player != null and combatant == GameManager.player:
		return player_hp_label
	return enemy_hp_label


func _stats_panel_for(combatant: Combatant) -> Control:
	if GameManager.player != null and combatant == GameManager.player:
		return player_stats_panel
	return enemy_stats_panel


func _flash_label(label: Label, flash_color: Color) -> void:
	# Salta il flash se il label è già stato modificato di colore (override)
	# e ripristina il modulate a bianco al termine.
	label.modulate = flash_color
	var tw: Tween = create_tween()
	tw.tween_property(label, "modulate", Color.WHITE, FLASH_DURATION)


func _spawn_floating_text(reference: Control, text: String, color: Color) -> void:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 10
	game_ui.add_child(lbl)
	# Posiziona al centro-alto del pannello di riferimento, in coordinate locali a game_ui
	var ref_top_center: Vector2 = reference.global_position + Vector2(reference.size.x / 2.0, 0)
	var local: Vector2 = ref_top_center - game_ui.global_position
	lbl.position = local - Vector2(20, 8)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - FLOAT_DISTANCE, FLOAT_DURATION)
	tw.tween_property(lbl, "modulate:a", 0.0, FLOAT_DURATION)
	get_tree().create_timer(FLOAT_DURATION + 0.05).timeout.connect(lbl.queue_free)


func _on_xp_gained(amount: int, leveled_up: bool, new_level: int) -> void:
	_last_xp_gain = amount
	_last_leveled_up = leveled_up
	_last_new_level = new_level


func _on_player_turn_started() -> void:
	_refresh_player_hand()
	end_turn_button.visible = true
	save_button.visible = true


func _refresh_player_hand() -> void:
	_clear_player_hand()
	if GameManager.player == null:
		return
	var mana: int = GameManager.player.mana
	for c in GameManager.player.hand:
		var tile: Panel = CardTileScene.instantiate()
		player_hand_container.add_child(tile)
		tile.setup(c)
		tile.clicked.connect(_on_card_tile_clicked)
		if c.mana_cost > mana:
			tile.set_interactive(false)
	player_hand_container.move_child(end_turn_button, -1)


func _clear_player_hand() -> void:
	for child in player_hand_container.get_children():
		if child != end_turn_button:
			child.queue_free()


func _on_card_tile_clicked(card: Card) -> void:
	end_turn_button.visible = false
	GameManager.play_player_card(card)


func _on_end_turn_pressed() -> void:
	end_turn_button.visible = false
	GameManager.skip_player_turn()


func _on_combat_ended(winner: Combatant) -> void:
	end_turn_button.visible = false
	save_button.visible = false
	combat_log_text.append_text("\n🏆 Vince %s!" % winner.combatant_name)
	_clear_player_hand()
	_show_game_over(winner)


func _show_game_over(winner: Combatant) -> void:
	var player_won: bool = GameManager.player != null and winner == GameManager.player
	if player_won:
		var enemy_name: String = GameManager.enemy.combatant_name if GameManager.enemy != null else "il nemico"
		result_label.text = "VITTORIA!"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
		var xp_text := "\n+%d XP" % _last_xp_gain
		if _last_leveled_up:
			xp_text += "  ⬆  Livello %d!" % _last_new_level
		winner_label.text = "Hai sconfitto %s.%s" % [enemy_name, xp_text]
		restart_button.text = "Scegli Ricompensa"
	else:
		result_label.text = "SCONFITTA"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		winner_label.text = "Sei stato sconfitto da %s." % winner.combatant_name
		restart_button.text = "Menu Principale"
		_last_xp_gain = 0
		_last_leveled_up = false
	game_over_overlay.modulate.a = 0.0
	game_over_overlay.visible = true
	var tw: Tween = create_tween()
	tw.tween_property(game_over_overlay, "modulate:a", 1.0, 0.4)
