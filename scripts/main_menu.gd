extends Control

@onready var level_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LevelLabel
@onready var btn_resume: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BtnResume


func _ready() -> void:
	var meta := SaveManager.load_meta()
	_update_level_display(meta.level, meta.xp)
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BtnNewGame.pressed.connect(_on_new_game)
	btn_resume.pressed.connect(_on_resume)
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BtnMerchant.pressed.connect(_on_merchant)
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BtnQuit.pressed.connect(_on_quit)
	btn_resume.disabled = not (SaveManager.has_run() or SaveManager.has_map())


func _update_level_display(level: int, xp: int) -> void:
	if level >= GameManager.MAX_LEVEL:
		level_label.text = "Livello MAX  —  %d XP totali" % xp
	else:
		var xp_in_level := xp - (level - 1) * 100
		level_label.text = "Livello %d  —  %d / 100 XP" % [level, xp_in_level]


func _on_new_game() -> void:
	SaveManager.clear_run()
	SaveManager.clear_map()
	GameManager.pending_resume = false
	GameManager.map_mode = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_resume() -> void:
	if SaveManager.has_run():
		# Riprende il combattimento (eventualmente dentro una run da mappa)
		GameManager.pending_resume = true
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	elif SaveManager.has_map():
		# Riprende dalla mappa (nessun combattimento in corso)
		GameManager.map_mode = true
		MapManager.load_map()
		get_tree().change_scene_to_file("res://scenes/world_map.tscn")


func _on_merchant() -> void:
	get_tree().change_scene_to_file("res://scenes/merchant.tscn")


func _on_quit() -> void:
	get_tree().quit()
