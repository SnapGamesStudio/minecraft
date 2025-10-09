extends Node

const BASE_URL := "http://localhost:8000"
const ITEMS_DIR := "user://items/"
const TEXTURES_DIR := "user://textures/"
const SFX_DIR := "user://sfx/"

var pending_downloads := 0
var server_items := {}
var pending_resources := []

signal completed_download

func _ready():
	# Ensure directories exist
	for dir_path in [ITEMS_DIR, TEXTURES_DIR, SFX_DIR]:
		ensure_dir(dir_path)

	# Example: download all jsons from server
	#fetch_all_jsons()
	
	# Example: download "gun.tres" from server
	#download_item_with_dependencies("gun.tres", "items")

# ------------------------
# Directory helper
# ------------------------
func ensure_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		return  # Folder exists

	# Folder doesn't exist — open user:// and create recursively
	var base = DirAccess.open("user://")
	if base:
		base.make_dir_recursive(path)


# ------------------------
# Folder mapping
# ------------------------
func get_folder_from_name(file_name: String) -> String:
	if file_name.ends_with(".tres") or file_name.ends_with(".tscn"):
		return ITEMS_DIR
	elif file_name.ends_with(".png") or file_name.ends_with(".jpg"):
		return TEXTURES_DIR
	elif file_name.ends_with(".wav") or file_name.ends_with(".ogg"):
		return SFX_DIR
	else:
		return ITEMS_DIR


# ------------------------
# Download item and dependencies
# ------------------------
func download_item_with_dependencies(item_name: String, folder_key: String) -> void:
	pending_resources.append(item_name)
	var json_url := "%s/download_file/%s/%s.json" % [BASE_URL, folder_key, item_name]
	var http := HTTPRequest.new()
	add_child(http)
	pending_downloads += 1
	http.request_completed.connect(Callable(self, "_on_json_request_completed").bind(folder_key))
	http.request(json_url)


func _on_json_request_completed(result: int, response_code: int, headers: Array, body: PackedByteArray, folder_key: String) -> void:
	pending_downloads -= 1
	if response_code != 200:
		print("Failed to get JSON for folder:", folder_key)
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse JSON for folder:", folder_key, json.get_error_message())
		return

	var data = json.data

	# First, download all dependencies
	for dep_name in data.dependencies.keys():
		var dep = data.dependencies[dep_name]
		if dep.exists and "download_url" in dep:
			download_file(dep.path, dep_name, get_folder_from_name(dep_name))
		else:
			print("Dependency not found on server:", dep_name)

	# Then download the main item last
	download_file(data.path, data.name, get_folder_from_name(data.name))

	


# ------------------------
# Download single file
# ------------------------
func download_file(res_path: String, file_name: String, folder_path: String) -> void:
	var local_path = folder_path + file_name

	if FileAccess.file_exists(local_path):
		load_resource(local_path, res_path, file_name)
		return

	var url := "%s/download_file/%s/%s" % [BASE_URL, folder_path.get_file(), file_name]
	var http := HTTPRequest.new()
	add_child(http)
	pending_downloads += 1
	http.request_completed.connect(Callable(self, "_on_file_download_completed").bind(local_path, res_path, file_name))
	http.request(url)


func _on_file_download_completed(result: int, response_code: int, headers: Array, body: PackedByteArray, local_path: String, res_path: String, file_name: String) -> void:
	pending_downloads -= 1
	if response_code != 200:
		print("Failed to download:", file_name)
		return

	# Save file to disk
	var f = FileAccess.open(local_path, FileAccess.WRITE)
	f.store_buffer(body)
	f.close()
	print("Downloaded:", local_path)

	# Load resource correctly based on type
	load_resource(local_path, res_path, file_name)

	if pending_downloads == 0:
		print("All files downloaded and ready!")


# ------------------------
# Load resource based on type
# ------------------------
func load_resource(local_path: String, res_path: String, file_name: String) -> void:
	if file_name.ends_with(".tres") or file_name.ends_with(".tscn"):
		var r = ResourceLoader.load(local_path)
		if r:
			r.take_over_path(res_path)
			pending_resources.erase(file_name)
			print("pending_resources ",pending_resources)
			if pending_resources.is_empty():
				completed_download.emit()
				
			print("Resource override applied:", local_path)
			
			
			$Slot.item = load(local_path)
			print(local_path)
			$Slot.update_slot()
			
			
				
			

	elif file_name.ends_with(".png") or file_name.ends_with(".jpg"):
		var image = Image.load_from_file(local_path)
		if image:
			var texture = ImageTexture.create_from_image(image)
			texture.take_over_path(res_path)  # Important: override original path
			print("ImageTexture override applied:", res_path)
			$TextureRect.texture = load(res_path)
			
	elif file_name.ends_with(".wav"):
		var file = FileAccess.open(local_path, FileAccess.READ)
		if file:
			var audio = AudioStreamWAV.new()
			audio.data = file.get_buffer(file.get_length())
			file.close()
			audio.take_over_path(res_path)  # Override original path
			print("AudioStreamSample override applied:", res_path)

	elif file_name.ends_with(".ogg"):
		var audio = AudioStreamOggVorbis.new()
		audio.resource_path = local_path
		audio.take_over_path(res_path)  # Override original path
		print("AudioStreamOGGVorbis override applied:", res_path)

# ------------------------
# Fetch all JSON files from server
# ------------------------
func fetch_all_jsons() -> void:
	var url = "%s/list_jsons" % BASE_URL
	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(Callable(self, "_on_list_jsons_completed"))
	http.request(url)
	
# ------------------------
# Handle JSON list response
# ------------------------
func _on_list_jsons_completed(result: int, response_code: int, headers: Array, body: PackedByteArray) -> void:
	if response_code != 200:
		print("Failed to fetch JSON list from server!")
		return

	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		print("Failed to parse server JSON list:", json.get_error_message())
		return

	var data = json.data
	if "json_files" in data:
		for json_file_path in data["json_files"]:
			# Example: store in dictionary by file name
			var name = json_file_path.get_file().replace(".json", "")
			server_items[name] = json_file_path

	# Print all items available on server
	print("Available items on server:")
	for item_name in server_items.keys():
		print(" - ", item_name)
		download_item_with_dependencies(item_name,"items")

	# Optionally, you can now trigger downloads for specific items
	# Example: download_item_with_dependencies("gun", "items")
