# archiveZone.gd
extends Area2D

const UIPolish = preload("res://scripts/uiPolish.gd")

var player_nearby: bool = false

@onready var _archive_ui = %ArchiveUI

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$ExclaimIndicator.visible = not GameState.visited.get("archive", false)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_nearby = true
		%PromptLabel.text = "[Enter] Buka Pose Archive"
		UIPolish.show_control(%PromptLabel, true)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_nearby = false
		UIPolish.hide_control(%PromptLabel)

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):
		GameState.visited["archive"] = true
		$ExclaimIndicator.visible = false
		_archive_ui.open()
		UIPolish.hide_control(%PromptLabel)
