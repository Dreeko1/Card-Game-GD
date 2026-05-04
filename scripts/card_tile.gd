extends Panel

signal clicked(card: Card)

@onready var label: Label = $Label

const COLOR_RED   := Color(1.0, 0.2, 0.2)
const COLOR_WHITE := Color(1.0, 1.0, 1.0)

const HOVER_SCALE    := Vector2(1.08, 1.08)
const HOVER_DURATION := 0.12

var card: Card
var _interactive: bool = true
var _tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(p_card: Card) -> void:
	card = p_card
	label.text = "%s\n\n%s" % [card.card_name, card.description()]
	var red_suits := [Card.Suit.CUORI, Card.Suit.QUADRI]
	var color: Color = COLOR_RED if card.suit in red_suits else COLOR_WHITE
	label.add_theme_color_override("font_color", color)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_interactive(value: bool) -> void:
	_interactive = value
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
	modulate.a = 1.0 if value else 0.6


func _on_mouse_entered() -> void:
	if not _interactive:
		return
	_animate_scale(HOVER_SCALE)


func _on_mouse_exited() -> void:
	_animate_scale(Vector2.ONE)


func _animate_scale(target: Vector2) -> void:
	if _tween:
		_tween.kill()
	pivot_offset = size / 2.0
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "scale", target, HOVER_DURATION)


func _gui_input(event: InputEvent) -> void:
	if not _interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(card)
