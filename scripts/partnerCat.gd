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

	# Temukan sprite kucing dan simpan animasi default-nya
	await get_tree().process_frame
	for child in get_children():
		if child is AnimatedSprite2D:
			_cat_sprite = child
			_default_animation = child.animation
			break

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
	if not player_nearby or _phase != _Phase.NONE or _inventory_ui.visible:
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
				_phase = _Phase.QUIZ
				Dialogic.start(_get_quiz_timeline())
		_Phase.QUIZ:
			if not _on_final_pack:
				GameState.quiz_pack[cat_key] = GameState.quiz_pack.get(cat_key, 0) + 1
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
