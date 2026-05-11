extends Node2D

const PLAYER_SPEED     := 200.0
const ENCOUNTER_RADIUS := 70.0
const WORLD_BOUNDS     := Rect2(-700.0, -500.0, 1400.0, 1000.0)
const PLAYER_START     := Vector2(0.0, 460.0)

const NODE_WORLD_POS: Array[Vector2] = [
	Vector2(-280.0,  380.0),   # 0 — zona 1 sinistra
	Vector2( 300.0,  350.0),   # 1 — zona 1 destra
	Vector2(-380.0,   60.0),   # 2 — zona 2 sinistra
	Vector2( 120.0,   20.0),   # 3 — zona 2 centro
	Vector2( 350.0,  120.0),   # 4 — zona 2 destra
	Vector2( -60.0, -300.0),   # 5 — zona 3 boss
]

const MERCHANT_POS  := Vector2(150.0, 380.0)   # PLAYER_START + Vector2(150, -80)

@onready var _tilemap: TileMapLayer = $TileMapLayer

var _player: CharacterBody2D
var _camera: Camera2D
var _prompt_label: Label
var _player_info_label: Label
var _enemy_markers: Dictionary = {}
var _near_node_id: int = -1
var _near_merchant: bool = false
var _hud_layer: CanvasLayer


func _ready() -> void:
	_setup_tilemap()
	_setup_background()
	_setup_zone_bands()
	_setup_environment()
	_setup_merchant_marker()
	_setup_enemy_markers()
	_setup_player()
	_setup_hud()
	_update_hud()
	if MapManager.map_cleared:
		_show_cleared_overlay()


func _physics_process(_delta: float) -> void:
	_handle_movement()
	_check_encounters()
	_player.z_index = int(_player.position.y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.echo:
		if _near_merchant:
			get_tree().change_scene_to_file("res://scenes/merchant.tscn")
		elif _near_node_id >= 0:
			_trigger_combat(_near_node_id)


func _handle_movement() -> void:
	var dir := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))  - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()
	_player.velocity = dir * PLAYER_SPEED
	_player.move_and_slide()
	_player.position = _player.position.clamp(
		WORLD_BOUNDS.position + Vector2(20, 20),
		WORLD_BOUNDS.end - Vector2(20, 20)
	)


func _check_encounters() -> void:
	_near_node_id = -1
	_near_merchant = false

	if _player.position.distance_to(MERCHANT_POS) < ENCOUNTER_RADIUS:
		_near_merchant = true
		_prompt_label.text = "[ E ]  Visita il Mercante"
		_prompt_label.visible = true
		return

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


# Crea un'ImageTexture con un rombo isometrico verde per il terreno placeholder.
func _make_iso_tile_texture() -> ImageTexture:
	var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 128:
			var nx := absf(float(x) / 64.0 - 1.0)
			var ny := absf(float(y) / 32.0 - 1.0)
			var d := nx + ny
			if d <= 1.0:
				var col := Color(0.22, 0.48, 0.16) if d < 0.88 else Color(0.13, 0.28, 0.09)
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _setup_tilemap() -> void:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(128, 64)

	var src := TileSetAtlasSource.new()
	src.texture = _make_iso_tile_texture()
	src.texture_region_size = Vector2i(128, 64)
	src.create_tile(Vector2i(0, 0))
	var src_id := ts.add_source(src)

	_tilemap.tile_set = ts
	for col in range(-14, 15):
		for row in range(-10, 11):
			_tilemap.set_cell(Vector2i(col, row), src_id, Vector2i(0, 0))


func _setup_background() -> void:
	var bg := Polygon2D.new()
	bg.polygon = PackedVector2Array([
		WORLD_BOUNDS.position,
		Vector2(WORLD_BOUNDS.end.x, WORLD_BOUNDS.position.y),
		WORLD_BOUNDS.end,
		Vector2(WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.y),
	])
	bg.color = Color(0.06, 0.10, 0.06)
	bg.z_index = -3000
	add_child(bg)


func _setup_zone_bands() -> void:
	# Bande semi-trasparenti sopra le tile: zona 1 (sud) verde, 2 marrone, 3 rossa.
	var bands: Array = [
		[200.0,  500.0, Color(0.08, 0.22, 0.08, 0.18)],
		[-150.0, 200.0, Color(0.22, 0.17, 0.08, 0.18)],
		[-500.0, -150.0, Color(0.22, 0.08, 0.08, 0.18)],
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
		poly.z_index = -1000
		add_child(poly)


func _setup_environment() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42317

	var blocked: Array[Vector2] = NODE_WORLD_POS.duplicate()
	blocked.append(PLAYER_START)
	var placed: Array[Vector2] = []

	var attempts := 0
	while placed.size() < 25 and attempts < 600:
		attempts += 1
		var pos := Vector2(
			rng.randf_range(WORLD_BOUNDS.position.x + 80.0, WORLD_BOUNDS.end.x - 80.0),
			rng.randf_range(WORLD_BOUNDS.position.y + 80.0, WORLD_BOUNDS.end.y - 80.0)
		)
		var ok := true
		for b: Vector2 in blocked:
			if pos.distance_to(b) < 110.0:
				ok = false
				break
		if ok:
			for p: Vector2 in placed:
				if pos.distance_to(p) < 60.0:
					ok = false
					break
		if not ok:
			continue

		placed.append(pos)
		var env := Node2D.new()
		env.position = pos
		env.z_index = int(pos.y)
		add_child(env)

		var is_tree := rng.randf() < 0.62
		var vis := Polygon2D.new()
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		if is_tree:
			vis.polygon = PackedVector2Array([
				Vector2(  0.0, -28.0),
				Vector2( 14.0,  10.0),
				Vector2(-14.0,  10.0),
			])
			vis.color = Color(0.10, 0.28, 0.08)
			var shape := ConvexPolygonShape2D.new()
			shape.points = PackedVector2Array([
				Vector2(  0.0, -28.0),
				Vector2( 14.0,  10.0),
				Vector2(-14.0,  10.0),
			])
			col.shape = shape
		else:
			vis.polygon = PackedVector2Array([
				Vector2(-12.0, -7.0),
				Vector2( 12.0, -7.0),
				Vector2( 12.0,  7.0),
				Vector2(-12.0,  7.0),
			])
			vis.color = Color(0.44, 0.44, 0.50)
			var shape := RectangleShape2D.new()
			shape.size = Vector2(24.0, 14.0)
			col.shape = shape
		env.add_child(vis)
		body.add_child(col)
		env.add_child(body)


func _octagon(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


func _setup_merchant_marker() -> void:
	var marker := Node2D.new()
	marker.position = MERCHANT_POS
	marker.z_index = int(MERCHANT_POS.y)
	add_child(marker)

	var vis := Polygon2D.new()
	vis.polygon = _octagon(28.0)
	vis.color = Color(0.90, 0.72, 0.10)
	marker.add_child(vis)

	var lbl := Label.new()
	lbl.text = "Mercante"
	lbl.position = Vector2(-50.0, 38.0)
	lbl.custom_minimum_size = Vector2(100.0, 0.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = Color(1.0, 1.0, 1.0)
	marker.add_child(lbl)


func _setup_enemy_markers() -> void:
	for node: MapNodeData in MapManager.nodes:
		var marker := Node2D.new()
		marker.position = NODE_WORLD_POS[node.id]
		# Z basato su Y per il corretto ordinamento isometrico.
		marker.z_index = int(NODE_WORLD_POS[node.id].y)
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
	_player.z_index = int(PLAYER_START.y)
	add_child(_player)

	# Triangolo alto e stretto, adatto alla visuale isometrica.
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(  0.0, -28.0),
		Vector2( 10.0,  14.0),
		Vector2(-10.0,  14.0),
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
