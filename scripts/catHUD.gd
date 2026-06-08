# catHUD.gd
extends CanvasLayer

@export var cat_key: String

var _mood_label: Label
var _last_mood: int = -1

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	vbox.position = Vector2(12, 12)
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	var name_label := Label.new()
	name_label.text = cat_key.capitalize()
	name_label.add_theme_font_size_override("font_size", 40)
	vbox.add_child(name_label)

	_mood_label = Label.new()
	_mood_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_mood_label)

	_refresh_mood()

func _process(_delta: float) -> void:
	var current := GameState.mood.get(cat_key, 0) as int
	if current != _last_mood:
		_refresh_mood()

func _refresh_mood() -> void:
	_last_mood = GameState.mood.get(cat_key, 0) as int
	_mood_label.text = "Mood: %d" % _last_mood
