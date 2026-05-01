extends Area2D

@export var cat_key: String
@export var greeting_timeline: String
@export var idle_timeline: String

var player_nearby: bool = false

enum _Phase { NONE, INTRO, QUIZ }
var _phase: _Phase = _Phase.NONE
var _on_final_pack: bool = false

var _inventory_ui: CanvasLayer
var _cat_sprite: AnimatedSprite2D
var _default_animation: String = ""
var _pose_timer: Timer
var _showing_archive_msg: bool = false
var _quit_mid_quiz: bool = false
var _redo_mode: bool = false
var _redo_overlay: CanvasLayer
var _redo_vbox: VBoxContainer

const PACK_LABELS: Array[String] = ["Easy 1", "Easy 2", "Medium 1", "Medium 2", "Hard"]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	Dialogic.timeline_ended.connect(_on_dialog_ended)
	Dialogic.signal_event.connect(_on_dialogic_signal)

	_inventory_ui = preload("res://scripts/inventoryUI.gd").new()
	_inventory_ui.setup(cat_key)
	_inventory_ui.item_given.connect(_on_item_given)
	_inventory_ui.closed.connect(_on_inventory_closed)
	add_child(_inventory_ui)

	_pose_timer = Timer.new()
	_pose_timer.one_shot = true
	_pose_timer.timeout.connect(_revert_animation)
	add_child(_pose_timer)

	_build_redo_overlay()

	# Temukan sprite kucing dan simpan animasi default-nya
	await get_tree().process_frame
	for child in get_children():
		if child is AnimatedSprite2D:
			_cat_sprite = child
			_default_animation = child.animation
			break

func _build_redo_overlay() -> void:
	_redo_overlay = CanvasLayer.new()
	_redo_overlay.visible = false
	add_child(_redo_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_redo_overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_redo_overlay.add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	_redo_vbox = VBoxContainer.new()
	_redo_vbox.custom_minimum_size = Vector2(280, 0)
	_redo_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(_redo_vbox)

func _show_redo_popup() -> void:
	for child in _redo_vbox.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Mau ngapain?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_redo_vbox.add_child(title)

	var current_pack: int = GameState.quiz_pack.get(cat_key, 0)
	var next_timeline := "%s_quiz_%d" % [cat_key, current_pack + 1]

	if Dialogic.timeline_exists(next_timeline):
		var btn := Button.new()
		btn.text = "Lanjut soal baru"
		btn.pressed.connect(_on_redo_next_pressed)
		_redo_vbox.add_child(btn)

	var sep := HSeparator.new()
	_redo_vbox.add_child(sep)

	var lbl := Label.new()
	lbl.text = "Latihan ulang:"
	_redo_vbox.add_child(lbl)

	for i in range(current_pack):
		var pack_lbl: String = PACK_LABELS[i] if i < PACK_LABELS.size() else "Pack %d" % (i + 1)
		var btn := Button.new()
		btn.text = pack_lbl
		btn.pressed.connect(_on_redo_pack_selected.bind(i + 1))
		_redo_vbox.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Nanti aja"
	cancel_btn.pressed.connect(_close_redo_popup)
	_redo_vbox.add_child(cancel_btn)

	_redo_overlay.visible = true

func _close_redo_popup() -> void:
	_redo_overlay.visible = false
	if player_nearby:
		%PromptLabel.visible = true
		_update_prompt()

func _on_redo_next_pressed() -> void:
	_redo_overlay.visible = false
	_redo_mode = false
	_phase = _Phase.QUIZ
	Dialogic.start(_get_quiz_timeline())

func _on_redo_pack_selected(pack_num: int) -> void:
	_redo_overlay.visible = false
	_redo_mode = true
	_phase = _Phase.QUIZ
	Dialogic.start("%s_quiz_%d" % [cat_key, pack_num])

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_nearby = true
		%PromptLabel.visible = true
		_update_prompt()

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_nearby = false
		%PromptLabel.visible = false

func _update_prompt() -> void:
	if _has_food_in_inventory():
		%PromptLabel.text = "[Enter] Ajak ngobrol  |  [F] Beri makan"
		%PromptLabel.offset_top = -30.0
	else:
		%PromptLabel.text = "[Enter] Ajak ngobrol"
		%PromptLabel.offset_top = -23.0

func _has_food_in_inventory() -> bool:
	var inv: Dictionary = GameState.inventory.get(cat_key, {})
	for item_id in inv:
		if inv[item_id] > 0:
			return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby or _phase != _Phase.NONE or _inventory_ui.visible or _redo_overlay.visible:
		return
	if event.is_action_pressed("ui_accept"):
		_start_intro()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_inventory_ui.open()
			%PromptLabel.visible = false

func _on_item_given(pose: String, is_new_pose: bool) -> void:
	if pose != "" and _cat_sprite != null and _cat_sprite.sprite_frames.has_animation(pose):
		_pose_timer.stop()
		_cat_sprite.play(pose)
		var frame_count: int = _cat_sprite.sprite_frames.get_frame_count(pose)
		var speed: float = _cat_sprite.sprite_frames.get_animation_speed(pose)
		var duration: float = clampf((frame_count / speed) * 3.0, 2.0, 6.0)
		_pose_timer.start(duration)

	if is_new_pose:
		_showing_archive_msg = true
		%PromptLabel.visible = true
		%PromptLabel.text = "Pose \"%s\" has been added to the archive!" % pose.capitalize()
		%PromptLabel.offset_top = -30.0

func _on_inventory_closed() -> void:
	if _showing_archive_msg:
		return
	if player_nearby:
		%PromptLabel.visible = true
		_update_prompt()

func _revert_animation() -> void:
	if _cat_sprite != null and _default_animation != "":
		_cat_sprite.play(_default_animation)
	_showing_archive_msg = false
	if player_nearby:
		%PromptLabel.visible = true
		_update_prompt()

func _start_intro() -> void:
	_phase = _Phase.INTRO
	%PromptLabel.visible = false
	var has_greeted: bool = GameState.greeted.get(cat_key, false)
	Dialogic.start(greeting_timeline if not has_greeted else idle_timeline)

func _get_quiz_timeline() -> String:
	var pack_num: int = GameState.quiz_pack.get(cat_key, 0) + 1
	var name := "%s_quiz_%d" % [cat_key, pack_num]
	if Dialogic.timeline_exists(name):
		_on_final_pack = false
		return name
	_on_final_pack = true
	return "%s_quiz_done" % cat_key

func _on_dialog_ended() -> void:
	match _phase:
		_Phase.INTRO:
			if not GameState.greeted.get(cat_key, false):
				GameState.greeted[cat_key] = true
				_phase = _Phase.NONE
				if player_nearby:
					%PromptLabel.visible = true
					_update_prompt()
			else:
				var current_pack: int = GameState.quiz_pack.get(cat_key, 0)
				if current_pack > 0:
					_phase = _Phase.NONE
					_show_redo_popup()
				else:
					_phase = _Phase.QUIZ
					Dialogic.start(_get_quiz_timeline())
		_Phase.QUIZ:
			if not _quit_mid_quiz and not _redo_mode and not _on_final_pack:
				GameState.quiz_pack[cat_key] = GameState.quiz_pack.get(cat_key, 0) + 1
			_quit_mid_quiz = false
			_redo_mode = false
			_phase = _Phase.NONE
			if player_nearby:
				%PromptLabel.visible = true
				_update_prompt()

func _on_dialogic_signal(arg: Variant) -> void:
	var parts := str(arg).split(" ")
	match parts[0]:
		"correct":
			GameState.mood[cat_key] = GameState.mood.get(cat_key, 0) + 1
			GameState.mood_accumulated += 1
			GameState.coins += 10
		"wrong":
			pass
		"quit":
			_quit_mid_quiz = true
