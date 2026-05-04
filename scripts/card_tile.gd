extends Panel

signal clicked(card: Card)

@onready var label: Label = $Label

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
	label.text = "%s\n\n%s\n%d mana" % [card.card_name, card.description, card.mana_cost]
	label.add_theme_color_override("font_color", _color_for_type(card.type))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _color_for_type(p_type: Card.Type) -> Color:
	match p_type:
		Card.Type.ATTACK: return Color(1.0, 0.35, 0.35)
		Card.Type.BLOCK:  return Color(0.4, 0.7, 1.0)
		Card.Type.HEAL:   return Color(0.45, 1.0, 0.55)
		Card.Type.BUFF:   return Color(1.0, 0.92, 0.45)
		Card.Type.DEBUFF: return Color(0.9, 0.5, 1.0)
	return Color(1.0, 1.0, 1.0)


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
