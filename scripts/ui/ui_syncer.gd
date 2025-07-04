extends Node

@export var inventory_holder:HBoxContainer


var server_ui_info:Dictionary = {}
var opened_ui:Vector3 ## tells the server which ui is opened


func _ready() -> void:
	Globals.sync_add_metadata.connect(add_metadata)
	#Globals.sync_change_open.connect(sync_change_open)
	#
	#Globals.remove_ui.connect(remove_ui)
	#Globals.open_inventory.connect(open_ui)
	#Globals.new_ui.connect(new_ui)
	#Globals.sync_ui_change.connect(ui_updated)


func new_ui(position: Vector3, scene_path: String) -> void:
	server_make_ui.rpc_id(1,position,scene_path)

func open_ui(position: Vector3) -> void:
	check_server.rpc_id(1, position)
	Opened_ui.rpc_id(1, position)


func ui_updated(index: int, item_path: String, amount: int, parent: String, health: float, rot: int) -> void:
	#print("updated")
	send_to_server.rpc(index,item_path,amount,parent,health,rot)


@rpc("any_peer", "call_local")
func send_to_server(index: int, item_path: String, amount: int, parent: String, health:float, rot: int) -> void:
	if multiplayer.is_server():
		#print("openui ",opened_ui)
		if opened_ui == Vector3.ZERO: return
		if !server_ui_info.has(str(opened_ui)): return
		server_ui_info[str(opened_ui)].inventory[str(index)] = {
			"item_path":item_path,
			"amount":amount,
			"parent":parent,
			"health":health,
			"rot":rot
		}
		#print(server_ui_info)


@rpc("any_peer", "call_local")
func server_make_ui(position: Vector3, scene_path: String) -> void:
	server_ui_info[str(position)] = {
		"scene": scene_path,
		"inventory": {}
	}


@rpc("any_peer", "call_local")
func check_server(position: Vector3) -> void:
	#print(server_ui_info.has(position)," ", str(position),"  ", server_ui_info)
	if !server_ui_info.has(str(position)): return
	var server_data: Dictionary = server_ui_info[str(position)]
	give_clients.rpc_id(multiplayer.get_remote_sender_id(), server_data, position)


@rpc("any_peer", "call_local")
func give_clients(server_data: Dictionary, position:Vector3) -> void:
	var ui = load(server_data.scene).instantiate()
	ui.id = position
	inventory_holder.add_child(ui)
	
	ui.open(server_data.inventory)
	inventory_holder.show()
	#print(server_data.inventory)


@rpc("any_peer", "call_local")
func Opened_ui(id: Vector3) -> void:
	## gives the id to the server to use
	opened_ui = id


@rpc("any_peer","call_local")
func remove_ui(id: Vector3) -> void:
	server_ui_info.erase(str(id))

func save():
	if multiplayer.is_server():
		var save_dict = {
			"server_ui_info":server_ui_info
		}
		return save_dict

func add_metadata(pos,metadata):
	sync_add_metadata.rpc_id(1,pos,metadata)
	
	
@rpc("any_peer","call_local")
func sync_add_metadata(pos,metadata):
	var t = get_tree().get_first_node_in_group("VoxelTerrain") as VoxelTerrain
	t.get_voxel_tool().set_voxel_metadata(pos,metadata)
