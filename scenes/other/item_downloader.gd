extends Node

var fnished_requests:int = 0
var server_url := "http://127.0.0.1:8000"
var packages := {}  # Dictionary of { id: { "item": Resource, "folder": String } }
var package_data: Dictionary = {}
var temp_files := []


var encryption_pass := "my_super_secret_password"  # keep this secret

func _ready():
	pass
	# Example: download a package
	#download_package("2dbea560")

func get_packages(caller:Callable):
	var http := HTTPRequest.new()
	add_child(http)
	http.request("%s/list" % server_url)
	http.request_completed.connect(caller)
	
func download_package(package_id: String) -> void:
	var url = "%s/download/%s" % [server_url, package_id]
	var http_downloader = HTTPRequest.new()
	add_child(http_downloader)
	http_downloader.request_completed.connect(_download_request_completed)
	http_downloader.request(url)


func _download_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("Download failed: %s" % response_code)
		return
	
	# Extract the ID from the headers
	var package_id: String = ""
	for header in headers:
		# compare lowercased prefix to be safe
		if header.to_lower().begins_with("x-package-id:"):
			var colon_index := header.find(":")
			if colon_index != -1:
				# take everything after the first colon and strip whitespace
				package_id = header.substr(colon_index + 1).strip_edges()
			break

	print("Downloaded package ID:", package_id)
	
	
	var temp_zip = str("user://" + package_id + ".zip")
	var f = FileAccess.open(temp_zip, FileAccess.WRITE)
	f.store_buffer(body)
	f.close()

	var zip = ZIPReader.new()
	var err = zip.open(temp_zip)
	if err != OK:
		push_error("Failed to open ZIP")
		return

	for filename in zip.get_files():
		var file_bytes = zip.read_file(filename)
		package_data[filename.get_file()] = file_bytes
		
		#print(filename," ",file_bytes)
		
		
		# Save encrypted directly to disk
		var temp_path = "user://%s" % filename
		var file = FileAccess.open(temp_path, FileAccess.WRITE)
		file.store_buffer(file_bytes)
		file.close()
			
		register_temp_file(temp_path)
		print("✅ Encrypted and saved:", filename)

	zip.close()
	#print(package_data)
	
	fnished_requests += 1
	print("All files encrypted and saved.")
		
# Load encrypted .tres
#func load_encrypted_tres(filename: String) -> Resource:
	#var enc_path = "user://enc_%s.enc" % filename
	#if not FileAccess.file_exists(enc_path):
	#	push_error("Encrypted file not found: %s" % filename, " attempt path : %s" % enc_path)
	#return null

	#var f = FileAccess.open_encrypted_with_pass(enc_path, FileAccess.READ, encryption_pass)
	#var decrypted_bytes = f.get_buffer(f.get_length())
	#f.close()
	# Write temporary .tres for ResourceLoader
	
	#if filename == "sand.tres":
	#	var grass = load_encrypted_tres("Sand.png")
		#print("Sand ",grass)
	
	#var temp_tres_path = "user://%s" % filename
	#f = FileAccess.open(temp_tres_path, FileAccess.WRITE)
	#f.store_buffer(decrypted_bytes)
	#f.close()
	#register_temp_file(temp_tres_path)
		
	#var res = ResourceLoader.load(temp_tres_path)
	#if res == null:
		#push_error("Failed to load resource: %s" % filename)
		#return null
	
	#print("✅ Loaded resource:", filename)
	#return res


func load_tres_from_package(filename: String):
	if not package_data.has(filename):
		push_error("File not found in package: %s" % filename)
		return null
		

	# Write the bytes to a temp file
	var temp_path = "user://%s" % filename
	#var f = FileAccess.open(temp_path, FileAccess.WRITE)
	#f.store_buffer(package_data[filename])
	#f.close()
	
	if filename.get_extension() == "png":

		var image: Image = Image.new()
		var load_err := image.load(temp_path)
		assert(load_err == OK, "Failed to load pic at: " + temp_path)

		var texture: Texture2D = ImageTexture.create_from_image(image)
		return texture
	# Load as resource
	var res = ResourceLoader.load(temp_path)
	if res == null:
		push_error("Failed to load resource: %s" % filename)
		return null

	print("✅ Loaded resource:", filename, " -> ", res)
	return res

func register_temp_file(path: String) -> void:
	temp_files.append(path)

func _exit_tree() -> void:
	for path in temp_files:
		delete_temp_file(path)
	temp_files.clear()


func delete_temp_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var dir = DirAccess.open(path.get_base_dir())
	if dir:
		var err = dir.remove(path.get_file())
		if err != OK:
			push_warning("Failed to delete temp file: %s" % path)
		else:
			print("Deleted temp file:", path)

func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	#fnished_requests += 1
	
	if response_code != 200:
		push_error("Failed to get packages list: %s" % response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) == TYPE_DICTIONARY and data.has("packages"):
		var ids = data["packages"]
		print("📦 Available package IDs:", ids)
		for id in ids:
			download_package(id)
	else:
		push_warning("Unexpected response format")
