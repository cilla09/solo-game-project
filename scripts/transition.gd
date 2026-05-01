# transition.gd
extends CanvasLayer

signal transition_finished

func fade_to_scene(path: String) -> void:
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(path)
	$AnimationPlayer.play("fade_in")
	await $AnimationPlayer.animation_finished
	emit_signal("transition_finished")
