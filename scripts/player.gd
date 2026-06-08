# player.gd
extends CharacterBody2D

const SPEED = 150.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_walk_anim: String = "walk-down"

func _physics_process(_delta: float) -> void:
	if Dialogic.current_timeline != null:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	var direction := Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		_update_animation(direction)
	else:
		_play_idle()

	velocity = direction * SPEED
	move_and_slide()

func _play_idle() -> void:
	if anim.animation != last_walk_anim or anim.is_playing():
		anim.play(last_walk_anim)
		anim.frame = 0
		anim.pause()

func _update_animation(dir: Vector2) -> void:
	# Prioritaskan sumbu yang lebih dominan saat diagonal
	if abs(dir.x) >= abs(dir.y):
		if dir.x > 0:
			last_walk_anim = "walk-right"
		else:
			last_walk_anim = "walk-left"
	else:
		if dir.y > 0:
			last_walk_anim = "walk-down"
		else:
			last_walk_anim = "walk-up"
	anim.play(last_walk_anim)
