# coinsHUD.gd
extends CanvasLayer

var _label: Label
var _last_coins: int = -1

func _ready() -> void:
	layer = 10

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.anchor_left = 1.0
	_label.anchor_right = 0.9
	_label.anchor_top = 0.0
	_label.anchor_bottom = 0.0
	_label.offset_left = -120.0
	_label.offset_right = -12.0
	_label.offset_top = 10.0
	_label.offset_bottom = 36.0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 48)
	add_child(_label)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	visible = scene != null and scene.name != "MainMenu"

	if visible:
		var coins := GameState.coins
		if coins != _last_coins:
			_last_coins = coins
			_label.text = "Coins: %d" % coins
