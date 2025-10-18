extends MultiplayerSpawner

signal spawned_object(id:int, object)


func _ready() -> void:
	set_multiplayer_authority(1)
	spawn_function = custom_spawn
	despawned.emit()
	Globals.add_object.connect(spawn_object)
	spawned_object.emit()
	
func print_spawned_object(id:int,object):
	print("spawned ",id,object)

@rpc("authority")
func spawn_object(data := []) -> void:
	if not multiplayer.is_server(): return
	spawn(data)

func custom_spawn(data: Array) -> Node:
	var id
	var spawn_position
	var instance_scene_path
	var item_path
	var amount
	if data.size() >= 1:
		id = data[0]
	if data.size() >= 2:
		spawn_position = data[1]
	if data.size() >= 3:
		instance_scene_path = data[2]
	if data.size() >= 4:
		item_path= data[3]
	if data.size() >= 5:
		amount = data[4]
	
	var object = load(instance_scene_path).instantiate()
	
	if typeof(spawn_position) == TYPE_TRANSFORM3D:
		object.global_transform = spawn_position
	elif typeof(spawn_position) == TYPE_VECTOR3:
		object.position = spawn_position
	
	if item_path != null:
		if "item" in object:
			object.item = load(item_path)
		elif "resource" in object:
			object.resource = load(item_path)
		print(load(item_path))
			
	if amount != null:
		object.amount = amount
		
	object.set_multiplayer_authority(id,true)
	
	spawned_object.emit(id, object)
	return object
	
