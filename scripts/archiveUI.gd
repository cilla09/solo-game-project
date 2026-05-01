extends CanvasLayer

const ALL_POSES: Array = [
	{"name": "donut sleep",  "description": "Curled up tight, fast asleep."},
	{"name": "loaf lick",    "description": "Grooming in loaf position."},
	{"name": "loaf yawn",    "description": "A satisfying loaf yawn."},
	{"name": "loaf yes",     "description": "Happily bobbing with joy!"},
	{"name": "out sleep",    "description": "Completely knocked out."},
	{"name": "proud",        "description": "Standing tall and majestic."},
	{"name": "scared",       "description": "What was THAT?!"},
	{"name": "sit itch",     "description": "Getting that hard-to-reach spot."},
	{"name": "sit lick",     "description": "Grooming while seated."},
	{"name": "sit yawn",     "description": "So sleepy after a long day."},
	{"name": "standing",     "description": "Alert and on all fours."},
	{"name": "standup lick", "description": "Standing tall for a good clean."},
]

const CAT_KEYS: Array = ["mochi", "koko", "bao"]
const CAT_LABELS: Dictionary = {"mochi": "Mochi", "koko": "Koko", "bao": "Bao"}

var _sprite_frames: Dictionary = {}  # cat_key -> SpriteFrames
var _current_tab: String = "mochi"
var _tab_buttons: Dictionary = {}
var _content_containers: Dictionary = {}
var _stats_label: Label

func _ready() -> void:
	visible = false
	_load_sprite_frames()
	_build_ui()

func _load_sprite_frames() -> void:
	var sources: Array = [
		{"scene": "res://scenes/main/MochiRoom.tscn", "cat_node": "WhiteCat", "key": "mochi"},
		{"scene": "res://scenes/main/KokoRoom.tscn",  "cat_node": "BlackCat", "key": "koko"},
		{"scene": "res://scenes/main/BaoRoom.tscn",   "cat_node": "OrangeCat", "key": "bao"},
	]
	for src in sources:
		var scene = load(src["scene"])
		if not scene:
			continue
		var node = scene.instantiate()
		var cat = node.find_child(src["cat_node"], true, false)
		if cat is AnimatedSprite2D:
			_sprite_frames[src["key"]] = (cat as AnimatedSprite2D).sprite_frames
		node.free()

func open() -> void:
	_refresh_all_tabs()
	visible = true

func close() -> void:
	visible = false

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(860, 560)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "Pose Archive"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(close)
	title_row.add_child(close_btn)

	# Tab row
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_row)

	for cat_key in CAT_KEYS:
		var tab_btn := Button.new()
		tab_btn.text = CAT_LABELS[cat_key]
		tab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_btn.pressed.connect(_show_tab.bind(cat_key))
		tab_row.add_child(tab_btn)
		_tab_buttons[cat_key] = tab_btn
	_tab_buttons[_current_tab].disabled = true

	vbox.add_child(HSeparator.new())

	# Scrollable grid per cat (stacked, only one visible at a time)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var scroll_root := VBoxContainer.new()
	scroll_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(scroll_root)

	for cat_key in CAT_KEYS:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.visible = (cat_key == _current_tab)
		scroll_root.add_child(grid)
		_content_containers[cat_key] = grid

	vbox.add_child(HSeparator.new())

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stats_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_stats_label)

func _show_tab(cat_key: String) -> void:
	_tab_buttons[_current_tab].disabled = false
	_current_tab = cat_key
	_tab_buttons[_current_tab].disabled = true
	for key in _content_containers:
		_content_containers[key].visible = (key == cat_key)
	_update_stats(cat_key)

func _refresh_all_tabs() -> void:
	for cat_key in CAT_KEYS:
		_refresh_tab(cat_key)
	_update_stats(_current_tab)

func _refresh_tab(cat_key: String) -> void:
	var grid: GridContainer = _content_containers[cat_key]
	for child in grid.get_children():
		child.free()
	var discovered: Array = GameState.discovered_poses.get(cat_key, [])
	var frames: SpriteFrames = _sprite_frames.get(cat_key)
	for pose_data in ALL_POSES:
		grid.add_child(_make_pose_card(pose_data, pose_data["name"] in discovered, frames))

func _update_stats(cat_key: String) -> void:
	var discovered: Array = GameState.discovered_poses.get(cat_key, [])
	var count := 0
	for pose_data in ALL_POSES:
		if pose_data["name"] in discovered:
			count += 1
	_stats_label.text = "%s: %d / %d poses discovered" % [CAT_LABELS[cat_key], count, ALL_POSES.size()]

func _make_pose_card(pose_data: Dictionary, is_unlocked: bool, frames: SpriteFrames) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 10)
	card.add_child(inner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(vbox)

	# Sprite preview area (centered, fixed height)
	var preview_center := CenterContainer.new()
	preview_center.custom_minimum_size = Vector2(180, 180)
	vbox.add_child(preview_center)

	if is_unlocked and frames != null and frames.has_animation(pose_data["name"]):
		var svc := SubViewportContainer.new()
		svc.custom_minimum_size = Vector2(180, 180)
		svc.stretch = true
		preview_center.add_child(svc)

		var sv := SubViewport.new()
		sv.size = Vector2i(32, 32)
		sv.transparent_bg = true
		sv.disable_3d = true
		sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		svc.add_child(sv)

		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(16, 16)
		sprite.play(pose_data["name"])
		sv.add_child(sprite)
	else:
		var lock_rect := ColorRect.new()
		lock_rect.color = Color(0.12, 0.12, 0.12, 1.0)
		lock_rect.custom_minimum_size = Vector2(180, 180)
		preview_center.add_child(lock_rect)

		var lock_lbl := Label.new()
		lock_lbl.text = "?"
		lock_lbl.add_theme_font_size_override("font_size", 36)
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_rect.add_child(lock_lbl)

	# Pose name
	var name_lbl := Label.new()
	name_lbl.text = pose_data["name"].capitalize() if is_unlocked else "???"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = pose_data["description"] if is_unlocked else "Not yet discovered."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	return card

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
