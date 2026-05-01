extends Area2D

@export var target_scene: String
@export var prompt_text: String = "[Enter] Masuk"

@onready var prompt_label: Label = %PromptLabel

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

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
		get_tree().change_scene_to_file("res://scenes/" + target_scene + ".tscn")
