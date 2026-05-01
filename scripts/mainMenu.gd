extends Node2D

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainRoom.tscn")

func _on_load_pressed() -> void:
	if SaveSystem.save_exists(0):
		SaveSystem.load_game(0)
		get_tree().change_scene_to_file("res://scenes/main/MainRoom.tscn")
	else:
		print("No save file found")
		
func _on_quit_pressed() -> void:
	get_tree().quit()
