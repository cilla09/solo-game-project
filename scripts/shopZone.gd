# shopZone.gd
extends Area2D

const UIPolish = preload("res://scripts/uiPolish.gd")

var player_nearby: bool = false

@onready var _shop_ui = %ShopUI

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$ExclaimIndicator.visible = not GameState.visited.get("shop", false)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_nearby = true
		%PromptLabel.text = "[Enter] Buka Shop"
		UIPolish.show_control(%PromptLabel, true)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_nearby = false
		UIPolish.hide_control(%PromptLabel)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):
		GameState.visited["shop"] = true
		$ExclaimIndicator.visible = false
		_shop_ui.open()
		UIPolish.hide_control(%PromptLabel)
