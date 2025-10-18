extends Node

@export var player:Player
@export var floor_ray:RayCast3D
@export var head_ray:RayCast3D

@export var voxel_blocky_type_library:VoxelBlockyTypeLibrary
@export var item_library:ItemsLibrary

const AIR_TYPE := 0

var last_voxel_pos:Vector3
var last_hit:VoxelRaycastResult
var voxel_pos:Vector3


func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if floor_ray.is_colliding():
			
			var collide_point = floor_ray.get_collision_point() - Vector3(0,1,0)
			voxel_pos = round(collide_point)
			
			if last_voxel_pos == voxel_pos: return
			
			last_voxel_pos = voxel_pos
			
			
			var voxel:int = Helper.terrian.get_voxel_tool().get_voxel(voxel_pos)
			
			if voxel != AIR_TYPE:
				var array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
				
				if !array.is_empty():
					var voxel_name = array[0]
					
					sfx.rpc(voxel_name,voxel_pos)
		var origin = head_ray.global_position
		var forward = Vector3.DOWN
		
		last_hit = Helper.terrian.get_voxel_tool().raycast(origin, forward, 1 ,2)
		
		if last_hit != null:
			sfx.rpc("water",last_hit.position)
			player.swimming = true
			Helper.enviroment.environment.fog_enabled = true
			
		else:
			player.swimming = false
			Helper.enviroment.environment.fog_enabled = false
				

@rpc("any_peer","call_local")
func sfx(voxel_name:String,pos:Vector3) -> void:
	var sound_effect = voxel_name
	Helper.sound_manager.play_sound(sound_effect,pos,"walk")
