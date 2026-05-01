# sfx.gd
extends Node

const _POSE_UNLOCK_STREAM = preload("res://assets/audio/Big Egg collect 1.wav")
const _CONFIRM_STREAM = preload("res://assets/audio/freesound_community-cash-register-purchase-87313.mp3")

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_pose_unlock() -> void:
	_player.stream = _POSE_UNLOCK_STREAM
	_player.play()

func play_confirm() -> void:
	_player.stream = _CONFIRM_STREAM
	_player.play()

func play_cancel() -> void:
	_player.stream = preload("res://assets/audio/Cancel 1.wav")
	_player.play()
