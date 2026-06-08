# mainRoom.gd
extends Node2D

const UIPolish = preload("res://scripts/uiPolish.gd")

@onready var save_prompt: Label = %PromptLabel
@onready var intro: String = "intro"
var near_save_point: bool = false

func _ready() -> void:
	save_prompt.visible = false
	$SavePoint.body_entered.connect(_on_save_enter)
	$SavePoint.body_exited.connect(_on_save_exit)
	if not GameState.intro_played:
		_start_intro()
	$SavePoint/ExclaimIndicator.visible = not GameState.visited.get("save", false)

func _on_save_enter(body: Node) -> void:
	if body.name == "Player":
		near_save_point = true
		save_prompt.text = "[Enter] Save Memory"
		UIPolish.show_control(save_prompt, true)

func _on_save_exit(body: Node) -> void:
	if body.name == "Player":
		near_save_point = false
		UIPolish.hide_control(save_prompt)

func _unhandled_input(event: InputEvent) -> void:
	if near_save_point and event.is_action_pressed("ui_accept"):
		GameState.visited["save"] = true
		$SavePoint/ExclaimIndicator.visible = false
		SaveSystem.save_game(0)
		save_prompt.text = "Memory saved."
		UIPolish.show_control(save_prompt, true)
		await get_tree().create_timer(1.5).timeout
		if near_save_point:
			save_prompt.text = "[Enter] Save Memory"

func _start_intro() -> void:
	GameState.intro_played = true
	Dialogic.start(intro)
