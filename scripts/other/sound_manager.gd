extends  Node


## the node has to the same as the type else wont work
func play_sound(type: StringName, pos: Vector3) -> void:
	var sound = find_child(type)
	if sound != null:
		sound.global_position = pos
		sound.play()


func play_UI_sound(type: StringName = &"UI") -> void:
	var sound = find_child(type)
	if sound != null:
		sound.play()
