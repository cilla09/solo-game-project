# changeSceneArea.gd
extends Area2D

const UIPolish = preload("res://scripts/uiPolish.gd")

@export var target_scene: String
@export var prompt_text: String = "[Enter] Masuk"

@onready var prompt_label: Label = %PromptLabel

var player_inside: bool = false
var _is_changing_scene: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var indicator := get_node_or_null("ExclaimIndicator")
	if indicator:
		indicator.visible = not GameState.visited.get(target_scene, false)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true
		prompt_label.text = prompt_text
		UIPolish.show_control(prompt_label, true)

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false
		UIPolish.hide_control(prompt_label)

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and not _is_changing_scene and event.is_action_pressed("ui_accept"):
		_is_changing_scene = true
		GameState.visited[target_scene] = true
		var indicator := get_node_or_null("ExclaimIndicator")
		if indicator:
			indicator.visible = false
		SaveSystem.save_game(0)
		prompt_label.text = "Memory auto-saved."
		UIPolish.show_control(prompt_label, true)
		await get_tree().create_timer(0.6).timeout
		Transition.fade_to_scene("res://scenes/" + target_scene + ".tscn")
