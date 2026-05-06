extends Control

# Posizioni centrali di ogni nodo sulla MapContainer (1920×1020 usabile sotto l'HUD).
# Layout isometrico: zone basse = facili, zone alte = difficili.
const NODE_POSITIONS := [
	[],                                                                   # zone 0 inutilizzata
	[Vector2(740, 700), Vector2(1180, 700)],                             # zone 1
	[Vector2(560, 450), Vector2(960, 390), Vector2(1360, 450)],         # zone 2
	[Vector2(960, 140)],                                                  # zone 3 (boss)
]

const NODE_SIZE := Vector2(150, 72)

const ZONE_LABELS := [
	"", "Zona 1 — Bosco", "Zona 2 — Pianura Oscura", "Zona 3 — Fortezza"
]

var _node_buttons: Dictionary = {}

@onready var map_container: Control = $MapContainer
@onready var player_info_label: Label = $HUD/HBox/PlayerInfoLabel
@onready var abandon_btn: Button = $HUD/HBox/AbandonBtn


func _ready() -> void:
	abandon_btn.pressed.connect(_on_abandon)
	_update_hud()
	_add_zone_labels()
	_draw_connections()
	_create_node_buttons()
	_refresh_nodes()
	if MapManager.map_cleared:
		_show_cleared_overlay()


func _update_hud() -> void:
	var xp_in_lv := GameManager.player_xp - (GameManager.player_level - 1) * 100
	player_info_label.text = "Lv.%d  |  %d/100 XP" % [GameManager.player_level, xp_in_lv]


func _add_zone_labels() -> void:
	var y_offsets := [710.0, 460.0, 155.0]
	for i in 3:
		var lbl := Label.new()
		lbl.text = ZONE_LABELS[i + 1]
		lbl.position = Vector2(40.0, y_offsets[i])
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(0.6, 0.6, 0.75)
		map_container.add_child(lbl)


func _draw_connections() -> void:
	for node: MapNodeData in MapManager.nodes:
		var from := _center_of(node)
		for conn_id: int in node.connections:
			var to_node := MapManager.get_node_by_id(conn_id)
			if to_node == null:
				continue
			var line := Line2D.new()
			line.add_point(from)
			line.add_point(_center_of(to_node))
			line.width = 3.0
			line.default_color = Color(0.35, 0.35, 0.55, 0.7)
			map_container.add_child(line)


func _create_node_buttons() -> void:
	for node: MapNodeData in MapManager.nodes:
		var btn := Button.new()
		btn.custom_minimum_size = NODE_SIZE
		btn.position = _center_of(node) - NODE_SIZE / 2.0
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		map_container.add_child(btn)
		_node_buttons[node.id] = btn
		var nid := node.id
		btn.pressed.connect(_on_node_pressed.bind(nid))


func _refresh_nodes() -> void:
	for id: int in _node_buttons:
		var node := MapManager.get_node_by_id(id)
		var btn: Button = _node_buttons[id]
		match node.state:
			MapNodeData.State.LOCKED:
				btn.disabled = true
				btn.modulate = Color(0.4, 0.4, 0.45)
				btn.text = "???"
			MapNodeData.State.AVAILABLE:
				btn.disabled = false
				btn.modulate = Color(1.0, 1.0, 1.0)
				btn.text = _node_label(node)
			MapNodeData.State.COMPLETED:
				btn.disabled = true
				btn.modulate = Color(0.3, 0.78, 0.3)
				btn.text = "✓ " + EnemyData.DATA[node.enemy_type]["name"]


func _center_of(node: MapNodeData) -> Vector2:
	return NODE_POSITIONS[node.zone][node.col]


func _node_label(node: MapNodeData) -> String:
	var d: Dictionary = EnemyData.DATA[node.enemy_type]
	var diff: int = d["difficulty"]
	return "%s\n%s%s" % [d["name"], "★".repeat(diff), "☆".repeat(3 - diff)]


func _on_node_pressed(node_id: int) -> void:
	var node := MapManager.get_node_by_id(node_id)
	GameManager.map_enemy_type = node.enemy_type
	GameManager.map_current_node_id = node_id
	GameManager.pending_combat = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_abandon() -> void:
	GameManager.map_mode = false
	SaveManager.clear_map()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_cleared_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -220.0
	panel.offset_top = -160.0
	panel.offset_right = 220.0
	panel.offset_bottom = 160.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Avventura completata!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Hai sconfitto tutti i nemici della mappa.\nInizia una nuova avventura dal menu principale."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "Menu Principale"
	btn.custom_minimum_size = Vector2(220, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)
	btn.pressed.connect(func() -> void:
		GameManager.map_mode = false
		SaveManager.clear_map()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
