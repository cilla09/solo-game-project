# interactionPrompt.gd
extends Area2D

const UIPolish = preload("res://scripts/uiPolish.gd")

@onready var save_prompt: Label = %PromptLabel

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true
		save_prompt.text = "[E] Interact"
		UIPolish.show_control(save_prompt, true)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false
		UIPolish.hide_control(save_prompt)

func is_player_near() -> bool:
	return player_inside
