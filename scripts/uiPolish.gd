extends RefCounted

const _META_SHOW_TWEEN := "_ui_polish_show_tween"
const _META_IDLE_TWEEN := "_ui_polish_idle_tween"
const _META_BUTTON_READY := "_ui_polish_button_ready"

static func show_control(node: CanvasItem, idle := false, duration := 0.16) -> void:
	if node == null:
		return
	_kill_tween(node, _META_SHOW_TWEEN)
	_kill_tween(node, _META_IDLE_TWEEN)
	node.visible = true
	node.modulate.a = 0.0
	_prepare_control_pivot(node)
	if node is Control:
		(node as Control).scale = Vector2(0.96, 0.96)
	var tween := node.create_tween()
	node.set_meta(_META_SHOW_TWEEN, tween)
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if node is Control:
		tween.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		if idle and node.visible:
			start_idle(node)
	)

static func hide_control(node: CanvasItem, duration := 0.12) -> void:
	if node == null:
		return
	_kill_tween(node, _META_SHOW_TWEEN)
	_kill_tween(node, _META_IDLE_TWEEN)
	_prepare_control_pivot(node)
	var tween := node.create_tween()
	node.set_meta(_META_SHOW_TWEEN, tween)
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if node is Control:
		tween.tween_property(node, "scale", Vector2(0.98, 0.98), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		node.visible = false
		node.modulate.a = 1.0
		if node is Control:
			(node as Control).scale = Vector2.ONE
	)

static func start_idle(node: CanvasItem) -> void:
	if node == null or not node.visible:
		return
	_kill_tween(node, _META_IDLE_TWEEN)
	_prepare_control_pivot(node)
	var tween := node.create_tween()
	node.set_meta(_META_IDLE_TWEEN, tween)
	tween.set_loops()
	tween.set_parallel(true)
	if node is Control:
		tween.tween_property(node, "scale", Vector2(1.025, 1.025), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.chain().tween_property(node, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		tween.tween_property(node, "modulate:a", 0.82, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.chain().tween_property(node, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

static func polish_button(button: Button) -> void:
	if button == null or button.has_meta(_META_BUTTON_READY):
		return
	button.set_meta(_META_BUTTON_READY, true)
	_prepare_control_pivot(button)
	button.mouse_entered.connect(func(): _animate_button(button, Vector2(1.05, 1.05), 0.09))
	button.mouse_exited.connect(func(): _animate_button(button, Vector2.ONE, 0.10))
	button.focus_entered.connect(func(): _animate_button(button, Vector2(1.05, 1.05), 0.09))
	button.focus_exited.connect(func(): _animate_button(button, Vector2.ONE, 0.10))
	button.button_down.connect(func(): _animate_button(button, Vector2(0.96, 0.96), 0.06))
	button.button_up.connect(func(): _animate_button(button, Vector2(1.04, 1.04), 0.08))

static func polish_buttons(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if child is Button:
			polish_button(child)
		polish_buttons(child)

static func show_layer(layer: CanvasLayer, visual: CanvasItem, idle := false, duration := 0.16) -> void:
	if layer == null:
		return
	layer.visible = true
	show_control(visual, idle, duration)

static func hide_layer(layer: CanvasLayer, visual: CanvasItem, duration := 0.12) -> void:
	if layer == null:
		return
	hide_control(visual, duration)
	await layer.get_tree().create_timer(duration).timeout
	layer.visible = false

static func _animate_button(button: Button, target_scale: Vector2, duration: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	_kill_tween(button, _META_SHOW_TWEEN)
	_prepare_control_pivot(button)
	var tween := button.create_tween()
	button.set_meta(_META_SHOW_TWEEN, tween)
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _prepare_control_pivot(node: CanvasItem) -> void:
	if node is Control:
		var control := node as Control
		control.pivot_offset = control.size * 0.5

static func _kill_tween(node: Object, meta_key: String) -> void:
	if node.has_meta(meta_key):
		var tween = node.get_meta(meta_key)
		if tween is Tween and tween.is_valid():
			tween.kill()
		node.remove_meta(meta_key)
