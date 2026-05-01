# changeSceneArea.gd
extends Area2D

@export var target_scene: String
@export var prompt_text: String = "[Enter] Masuk"

@onready var prompt_label: Label = %PromptLabel

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var indicator := get_node_or_null("ExclaimIndicator")
	if indicator:
		indicator.visible = not GameState.visited.get(target_scene, false)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_inside = true
		prompt_label.visible = true
		prompt_label.text = prompt_text

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_inside = false
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_inside and event.is_action_pressed("ui_accept"):
		GameState.visited[target_scene] = true
		var indicator := get_node_or_null("ExclaimIndicator")
		if indicator:
			indicator.visible = false
		Transition.fade_to_scene("res://scenes/" + target_scene + ".tscn")
