extends Control

@onready var options_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer


func _ready() -> void:
	var rewards := RewardManager.generate_rewards(3)
	for option in rewards:
		_create_reward_button(option)


func _create_reward_button(option: Dictionary) -> void:
	var btn := Button.new()
	btn.text = RewardManager.reward_display_text(option)
	btn.custom_minimum_size = Vector2(320, 72)
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	options_container.add_child(btn)
	btn.pressed.connect(_on_reward_chosen.bind(option))


func _on_reward_chosen(option: Dictionary) -> void:
	RewardManager.apply_reward(option)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
