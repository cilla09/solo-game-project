# interactionPrompt.gd
extends Area2D

@onready var save_prompt: Label = %PromptLabel

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true
		save_prompt.visible = true
		save_prompt.text = "[E] Interact"

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false
		save_prompt.visible = false

func is_player_near() -> bool:
	return player_inside
