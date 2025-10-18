extends Node3D

func _ready() -> void:
	Helper.load_helper()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
