# mainMenu.gd
extends Node2D

const UIPolish = preload("res://scripts/uiPolish.gd")

func _ready() -> void:
	UIPolish.polish_buttons(self)

func _on_start_pressed() -> void:
	Transition.fade_to_scene("res://scenes/main/MainRoom.tscn")

func _on_load_pressed() -> void:
	if SaveSystem.save_exists(0):
		SaveSystem.load_game(0)
		Transition.fade_to_scene("res://scenes/main/MainRoom.tscn")
	else:
		print("No save file found")
		
func _on_quit_pressed() -> void:
	get_tree().quit()
