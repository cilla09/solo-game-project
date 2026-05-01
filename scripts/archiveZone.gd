# archiveZone.gd
extends Area2D

var player_nearby: bool = false

@onready var _archive_ui = %ArchiveUI

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$ExclaimIndicator.visible = not GameState.visited.get("archive", false)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_nearby = true
		%PromptLabel.visible = true
		%PromptLabel.text = "[Enter] Buka Pose Archive"

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_nearby = false
		%PromptLabel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_nearby and event.is_action_pressed("ui_accept"):
		GameState.visited["archive"] = true
		$ExclaimIndicator.visible = false
		_archive_ui.open()
		%PromptLabel.visible = false
