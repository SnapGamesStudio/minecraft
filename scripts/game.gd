extends Node3D
class_name Game

var player: Player
var is_fullscreen: bool = false

func _process(_delta: float) -> void:
	if Connection.is_server() or player == null: return
	
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
