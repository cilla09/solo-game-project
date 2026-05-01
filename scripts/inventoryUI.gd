extends CanvasLayer

const FOOD_DATA: Dictionary = {
	"kibble":        {"label": "Kibble",        "mood_boost": 8,   "pose_triggered": "loaf yes",    "requires_toy": ""},
	"fancy_fish":    {"label": "Fancy Fish",     "mood_boost": 15,  "pose_triggered": "loaf lick",   "requires_toy": "yarn_ball"},
	"treat_bag":     {"label": "Treat Bag",      "mood_boost": 6,   "pose_triggered": "sit lick",    "requires_toy": "yarn_ball"},
	"durian":        {"label": "Durian",         "mood_boost": -12, "pose_triggered": "scared",      "requires_toy": "feather_wand"},
	"catnip":        {"label": "Catnip",         "mood_boost": 12,  "pose_triggered": "standup lick","requires_toy": "feather_wand"},
	"warm_milk":     {"label": "Warm Milk",      "mood_boost": 15,  "pose_triggered": "donut sleep", "requires_toy": "cat_tower"},
	"laser_pointer": {"label": "Laser Pointer",  "mood_boost": 20,  "pose_triggered": "sit yawn",    "requires_toy": "cat_tower"},
	"mystery_bag":   {"label": "Mystery Bag",    "mood_boost": 0,   "pose_triggered": "",            "requires_toy": ""},
}

var cat_key: String = ""

var _overlay: ColorRect
var _items_container: VBoxContainer
var _feedback_label: Label
var _title_label: Label

signal item_given(pose: String, is_new_pose: bool)
signal closed

func _ready() -> void:
	visible = false
	_build_ui()

func setup(key: String) -> void:
	cat_key = key

func open() -> void:
	_refresh_list()
	visible = true

func close() -> void:
	visible = false
	emit_signal("closed")

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(340, 0)
	_overlay.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_title_label)

	vbox.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 180
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_container.add_theme_constant_override("separation", 6)
	scroll.add_child(_items_container)

	vbox.add_child(HSeparator.new())

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 11)
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_feedback_label)

	var close_btn := Button.new()
	close_btn.text = "Tutup"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)

func _refresh_list() -> void:
	_title_label.text = "Inventory — %s" % cat_key.capitalize()
	_feedback_label.text = ""

	for child in _items_container.get_children():
		child.queue_free()

	var inv: Dictionary = GameState.inventory.get(cat_key, {})
	var has_items := false

	for item_id in inv:
		var count: int = inv[item_id]
		if count <= 0 or not FOOD_DATA.has(item_id):
			continue
		has_items = true
		var data: Dictionary = FOOD_DATA[item_id]

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_items_container.add_child(card)

		var inner_margin := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			inner_margin.add_theme_constant_override("margin_" + side, 6)
		card.add_child(inner_margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		inner_margin.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = "%s  ×%d" % [data["label"], count]
		info.add_child(name_lbl)

		var effect_lbl := Label.new()
		var mood_str: String
		if item_id == "mystery_bag":
			mood_str = "+8~18 mood"
		elif data["mood_boost"] < 0:
			mood_str = "%d mood" % data["mood_boost"]
		else:
			mood_str = "+%d mood" % data["mood_boost"]
		effect_lbl.text = mood_str
		effect_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(effect_lbl)

		var give_btn := Button.new()
		give_btn.text = "Kasih"
		give_btn.custom_minimum_size.x = 70
		give_btn.pressed.connect(_on_give_pressed.bind(item_id, data))
		row.add_child(give_btn)

	if not has_items:
		var empty_lbl := Label.new()
		empty_lbl.text = "Tidak ada item untuk %s." % cat_key.capitalize()
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 12)
		_items_container.add_child(empty_lbl)

func _on_give_pressed(item_id: String, data: Dictionary) -> void:
	var inv: Dictionary = GameState.inventory.get(cat_key, {})
	if inv.get(item_id, 0) <= 0:
		return

	var boost: int
	var pose: String

	if item_id == "mystery_bag":
		boost = randi_range(8, 18)
		var candidates: Array = _mystery_candidates()
		pose = candidates[randi() % candidates.size()] if not candidates.is_empty() else ""
	else:
		boost = data["mood_boost"]
		pose = data["pose_triggered"]

	GameState.mood[cat_key] = GameState.mood.get(cat_key, 0) + boost
	if boost > 0:
		GameState.mood_accumulated += boost

	var is_new_pose := false
	if pose != "":
		var dp: Array = GameState.discovered_poses.get(cat_key, [])
		if not pose in dp:
			is_new_pose = true
			dp.append(pose)
			GameState.discovered_poses[cat_key] = dp

	inv[item_id] -= 1
	if inv[item_id] <= 0:
		inv.erase(item_id)
	GameState.inventory[cat_key] = inv

	emit_signal("item_given", pose, is_new_pose)
	close()

func _mystery_candidates() -> Array:
	var owned: Array = GameState.collectibles.get(cat_key, [])
	var poses: Array = []
	for food_id in FOOD_DATA:
		if food_id == "mystery_bag":
			continue
		var req: String = FOOD_DATA[food_id]["requires_toy"]
		if req == "" or req in owned:
			var p: String = FOOD_DATA[food_id]["pose_triggered"]
			if p != "" and not poses.has(p):
				poses.append(p)
	return poses

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
