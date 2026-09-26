extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

func _ready() -> void:
	get_tree().paused = false
	play_button.pressed.connect(_on_play_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	play_button.grab_focus()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/World.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
