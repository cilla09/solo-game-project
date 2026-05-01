extends Node2D

var _base_y: float

func _ready() -> void:
	_base_y = position.y
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", _base_y - 6, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _base_y, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-4, 0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.YELLOW)
