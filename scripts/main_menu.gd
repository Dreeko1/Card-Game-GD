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
	btn_resume.disabled = not SaveManager.has_run()


func _update_level_display(level: int, xp: int) -> void:
	if level >= GameManager.MAX_LEVEL:
		level_label.text = "Livello MAX  —  %d XP totali" % xp
	else:
		var xp_in_level := xp - (level - 1) * 100
		level_label.text = "Livello %d  —  %d / 100 XP" % [level, xp_in_level]


func _on_new_game() -> void:
	SaveManager.clear_run()
	GameManager.pending_resume = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_resume() -> void:
	GameManager.pending_resume = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_merchant() -> void:
	get_tree().change_scene_to_file("res://scenes/merchant.tscn")


func _on_quit() -> void:
	get_tree().quit()
