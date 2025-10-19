extends Node3D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

var ani_name:String

func use_item(item:ItemBase) -> void:
	if not item is ItemTool and not item is ItemFood:
		return
		
	if animation_player.is_playing(): return
	
	var ani = item.use_ani
	if ani == null: return
	
	ani_name = ani.resource_name
	
	var lib:AnimationLibrary = animation_player.get_animation_library("")
	
	if !lib.has_animation(ani.resource_name):
		lib.add_animation(ani.resource_name,ani)
	if animation_player.has_animation(ani.resource_name):
		animation_player.play(ani.resource_name)
		
		
func stop() -> void:
	if animation_player:
		if animation_player.has_animation(ani_name):
			var lib:AnimationLibrary = animation_player.get_animation_library("")
			animation_player.stop()
			lib.remove_animation(ani_name)
