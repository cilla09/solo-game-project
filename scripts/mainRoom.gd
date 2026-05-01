extends Node2D

@onready var save_prompt: Label = %PromptLabel
var near_save_point: bool = false

func _ready() -> void:
	save_prompt.visible = false
	$SavePoint.body_entered.connect(_on_save_enter)
	$SavePoint.body_exited.connect(_on_save_exit)

func _on_save_enter(body: Node) -> void:
	if body.name == "Player":
		near_save_point = true
		save_prompt.visible = true
		save_prompt.text = "[E] Save Memory"

func _on_save_exit(body: Node) -> void:
	if body.name == "Player":
		near_save_point = false
		save_prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if near_save_point and event.is_action_pressed("ui_accept"):
		SaveSystem.save_game(0)
		save_prompt.text = "Memory saved."
		await get_tree().create_timer(1.5).timeout
		if near_save_point:
			save_prompt.text = "[E] Save Memory"
