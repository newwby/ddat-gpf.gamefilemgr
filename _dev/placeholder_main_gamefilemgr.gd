extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var game_file_load_dialog = $GameFileLoadDialog


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	game_file_load_dialog.open_game_file_dialog()
#	emit_signal()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
