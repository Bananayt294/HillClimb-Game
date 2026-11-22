
extends CanvasLayer

@onready var restart_button: Button = $Control/CenterContainer/VBoxContainer/RestartButton


func _ready() -> void:

	# Draw above the game
	layer = 10

	# Allow buttons to work while the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)

	# Pause the game
	get_tree().paused = true


func _on_restart_pressed() -> void:

	# Unpause the game
	get_tree().paused = false

	# Restart the current level
	get_tree().reload_current_scene()
