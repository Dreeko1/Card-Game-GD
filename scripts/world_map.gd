extends Node2D

const PLAYER_SPEED     := 200.0
const ENCOUNTER_RADIUS := 70.0
const WORLD_BOUNDS     := Rect2(-700.0, -500.0, 1400.0, 1000.0)
const PLAYER_START     := Vector2(0.0, 440.0)

const NODE_WORLD_POS: Array[Vector2] = [
	Vector2(-220.0,  300.0),
	Vector2( 220.0,  300.0),
	Vector2(-380.0,   50.0),
	Vector2(   0.0,  -20.0),
	Vector2( 380.0,   50.0),
	Vector2(   0.0, -300.0),
]

const ZONE_LABELS := ["Zona 1 — Bosco", "Zona 2 — Pianura Oscura", "Zona 3 — Fortezza"]

var _player: CharacterBody2D
var _camera: Camera2D
var _prompt_label: Label
var _player_info_label: Label
var _enemy_markers: Dictionary = {}
var _near_node_id: int = -1
var _hud_layer: CanvasLayer


func _ready() -> void:
	_setup_background()
	_setup_zone_bands()
	_setup_paths()
	_setup_enemy_markers()
	_setup_player()
	_setup_hud()
	_update_hud()
	if MapManager.map_cleared:
		_show_cleared_overlay()


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_check_encounters()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		if _near_node_id >= 0:
			_trigger_combat(_near_node_id)


func _handle_movement() -> void:
	var dir := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	_player.velocity = dir.normalized() * PLAYER_SPEED
	_player.move_and_slide()
	var pad := Vector2(20.0, 20.0)
	_player.position = _player.position.clamp(
		WORLD_BOUNDS.position + pad,
		WORLD_BOUNDS.end - pad
	)


func _check_encounters() -> void:
	_near_node_id = -1
	for id: int in _enemy_markers:
		var node := MapManager.get_node_by_id(id)
		if node == null or node.state != MapNodeData.State.AVAILABLE:
			continue
		if _player.position.distance_to(NODE_WORLD_POS[id]) < ENCOUNTER_RADIUS:
			_near_node_id = id
			_prompt_label.text = "[ E ]  Combatti %s" % EnemyData.DATA[node.enemy_type]["name"]
			_prompt_label.visible = true
			return
	_prompt_label.visible = false


func _trigger_combat(node_id: int) -> void:
	var node := MapManager.get_node_by_id(node_id)
	GameManager.map_enemy_type = node.enemy_type
	GameManager.map_current_node_id = node_id
	GameManager.pending_combat = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _setup_background() -> void:
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		WORLD_BOUNDS.position,
		Vector2(WORLD_BOUNDS.end.x, WORLD_BOUNDS.position.y),
		WORLD_BOUNDS.end,
		Vector2(WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.y),
	])
	bg.color = Color(0.10, 0.15, 0.10)
	add_child(bg)


func _setup_zone_bands() -> void:
	# [y_top, y_bottom, color] — zona 1 in basso, zona 3 in alto
	var bands: Array = [
		[100.0,   500.0, Color(0.08, 0.22, 0.08, 0.30)],
		[-150.0,  100.0, Color(0.22, 0.17, 0.08, 0.30)],
		[-500.0, -150.0, Color(0.22, 0.08, 0.08, 0.30)],
	]
	for i in 3:
		var y_top: float = bands[i][0]
		var y_bot: float = bands[i][1]
		var col: Color   = bands[i][2]

		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(WORLD_BOUNDS.position.x, y_top),
			Vector2(WORLD_BOUNDS.end.x,      y_top),
			Vector2(WORLD_BOUNDS.end.x,      y_bot),
			Vector2(WORLD_BOUNDS.position.x, y_bot),
		])
		poly.color = col
		add_child(poly)

		var lbl := Label.new()
		lbl.text = ZONE_LABELS[i]
		lbl.position = Vector2(WORLD_BOUNDS.position.x + 16.0, y_top + 8.0)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(0.75, 0.75, 0.85)
		add_child(lbl)


func _setup_paths() -> void:
	for node: MapNodeData in MapManager.nodes:
		var from: Vector2 = NODE_WORLD_POS[node.id]
		for conn_id: int in node.connections:
			var line := Line2D.new()
			line.add_point(from)
			line.add_point(NODE_WORLD_POS[conn_id])
			line.width = 8.0
			line.default_color = Color(0.45, 0.38, 0.28, 0.9)
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode   = Line2D.LINE_CAP_ROUND
			add_child(line)


func _octagon(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _setup_enemy_markers() -> void:
	for node: MapNodeData in MapManager.nodes:
		var marker := Node2D.new()
		marker.position = NODE_WORLD_POS[node.id]
		add_child(marker)
		_enemy_markers[node.id] = marker

		var vis := Polygon2D.new()
		vis.polygon = _octagon(28.0)
		match node.state:
			MapNodeData.State.AVAILABLE:
				vis.color = Color(0.85, 0.45, 0.15)
			MapNodeData.State.LOCKED:
				vis.color = Color(0.28, 0.28, 0.38)
			MapNodeData.State.COMPLETED:
				vis.color = Color(0.20, 0.70, 0.30)
		marker.add_child(vis)

		var lbl := Label.new()
		lbl.position = Vector2(-55.0, 33.0)
		lbl.custom_minimum_size = Vector2(110.0, 0.0)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		match node.state:
			MapNodeData.State.LOCKED:
				lbl.text = "???"
				lbl.modulate = Color(0.55, 0.55, 0.60)
			MapNodeData.State.AVAILABLE:
				lbl.text = EnemyData.DATA[node.enemy_type]["name"]
				lbl.modulate = Color(1.0, 0.90, 0.60)
			MapNodeData.State.COMPLETED:
				lbl.text = "✓ " + EnemyData.DATA[node.enemy_type]["name"]
				lbl.modulate = Color(0.50, 1.0, 0.60)
		marker.add_child(lbl)


func _setup_player() -> void:
	_player = CharacterBody2D.new()
	_player.position = PLAYER_START
	add_child(_player)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(  0.0, -22.0),
		Vector2( 14.0,   0.0),
		Vector2(  0.0,  22.0),
		Vector2(-14.0,   0.0),
	])
	vis.color = Color(0.30, 0.60, 1.0)
	_player.add_child(vis)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	_player.add_child(col)

	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed   = 8.0
	_camera.limit_left   = int(WORLD_BOUNDS.position.x)
	_camera.limit_top    = int(WORLD_BOUNDS.position.y)
	_camera.limit_right  = int(WORLD_BOUNDS.end.x)
	_camera.limit_bottom = int(WORLD_BOUNDS.end.y)
	_player.add_child(_camera)


func _setup_hud() -> void:
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0.0, 50.0)
	_hud_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",  12)
	margin.add_theme_constant_override("margin_right", 12)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var abandon := Button.new()
	abandon.text = "Menu"
	abandon.custom_minimum_size = Vector2(90.0, 38.0)
	abandon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	abandon.pressed.connect(_on_abandon)
	hbox.add_child(abandon)

	var title := Label.new()
	title.text = "Mappa dell'Avventura"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	hbox.add_child(title)

	_player_info_label = Label.new()
	_player_info_label.custom_minimum_size  = Vector2(200.0, 0.0)
	_player_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_player_info_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(_player_info_label)

	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_top = -70.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 20)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_prompt_label.visible = false
	_hud_layer.add_child(_prompt_label)


func _update_hud() -> void:
	if _player_info_label == null:
		return
	var xp_in_lv := GameManager.player_xp - (GameManager.player_level - 1) * 100
	_player_info_label.text = "Lv.%d  |  %d/100 XP" % [GameManager.player_level, xp_in_lv]


func _on_abandon() -> void:
	GameManager.map_mode = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _show_cleared_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_layer.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -220.0
	panel.offset_top    = -160.0
	panel.offset_right  =  220.0
	panel.offset_bottom =  160.0
	_hud_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "Avventura completata!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 34)
	vbox.add_child(title_lbl)

	var sub := Label.new()
	sub.text = "Hai sconfitto tutti i nemici della mappa.\nInizia una nuova avventura dal menu principale."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "Menu Principale"
	btn.custom_minimum_size = Vector2(220.0, 50.0)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)
	btn.pressed.connect(func() -> void:
		GameManager.map_mode = false
		SaveManager.clear_map()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
