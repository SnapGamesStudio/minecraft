extends Control

@onready var checks: Timer = $Checks

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_scene: PackedScene
@export var loading_bar: ProgressBar

var sent_requests:int = 0
var python_client := Python_Item_Backend_Client.new()

signal checked_for_item
var has_item = false

func _ready() -> void:
	add_child(python_client)
	
	#if Connection.is_server():
		#start_scene()
		#return

	#else:
		#pass
		#start_scene()
		
	Backend.playerdata_updated.connect(check_items)

func _process(delta):
	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	
	
	

func start_scene() -> void:
	get_tree().call_deferred("change_scene_to_packed", multiplayer_scene)

func check_items():
	if Backend.playerdata:
		var inventory_data
		var hotbar_data
		var blueprint_data
		var upload_items:Array = []
		
		if Backend.playerdata.Inventory:
			inventory_data = JSON.parse_string(Backend.playerdata.Inventory)
		
		if Backend.playerdata.Hotbar:
			hotbar_data = JSON.parse_string(Backend.playerdata.Hotbar)
			
		if Backend.playerdata.Blueprints:
			blueprint_data = JSON.parse_string(Backend.playerdata.Blueprints)
			
		if inventory_data:
			for i in inventory_data:
				var item_path = inventory_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item ", item_path)
					var upload_files = get_item_resources(item_path)
					python_client.upload_files(upload_files)
					sent_requests += 1
					
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					sent_requests += 1
					print("missing item ",item_path)
					
		if hotbar_data:
			for i in hotbar_data:
				var item_path:String = hotbar_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item ", item_path)
					var upload_files = get_item_resources(item_path)
					python_client.upload_files(upload_files)
					sent_requests += 1
					
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					sent_requests += 1
					print("missing item ",item_path)
					
		if blueprint_data:
			for i in blueprint_data:
				var item_path:String = blueprint_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item ", item_path)
					var upload_files = get_item_resources(item_path)
					python_client.upload_files(upload_files)
					sent_requests += 1
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					sent_requests += 1
					print("missing item ",item_path)
					pass
		
	checks.start()

func _on_download_file_check(result: Dictionary):
	if result.get("exists", false):
		print("File exists on server in folder:", result["folder_id"])
		print("Godot path:", result["local_path"])
		python_client.download_folder_files(result["local_path"].get_file())
		sent_requests += 1
	else:
		print("File does not exist on server, safe to upload")

func get_item_resources(item_path:String) -> Array:
	var search : Array[String] = ["Texture2D","AudioStream","AudioStreamMP3","AudioStreamOggVorbis","AudioStreamWAV","PackedScene"]
	
	var save := [{"path":item_path,"local_path":item_path}]
	
	var item:ItemBase = load(item_path)
	
	var list = item.get_property_list()
	for variable in list:
		var class_ = variable.class_name
		#print(class_)
		
		if search.has(class_):
			if item.get(variable.name) != null:
				if class_ == "AudioStream":
					var stream:AudioStreamRandomizer = item.get(variable.name)
					var streams = stream.get_streams_count()
					for i in streams:
						save.append({"path":stream.get_stream(i).get_path(),"local_path":stream.get_stream(i).get_path()})
				save.append({"path":item.get(variable.name).get_path(),"local_path":item.get(variable.name).get_path()})
	
	return save


func _on_checks_timeout() -> void:
	if sent_requests == python_client.fnished_requests:
		start_scene()
