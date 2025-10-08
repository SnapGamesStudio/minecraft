extends Node

var package_data := {}
var current_package_id := ""

func _ready() -> void:
	download_package("db771fe3-6b3f-419b-b30a-440e8178a12c")
	
func download_package(package_id: String):
	current_package_id = package_id  # ✅ store the ID before request
	var url = "http://127.0.0.1:8000/download/%s" % package_id
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	http.request(url)

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Failed to download package:", response_code)
		return

	var temp_pck_path = "user://%s.pck" % current_package_id
	var file = FileAccess.open(temp_pck_path, FileAccess.WRITE)
	if file == null:
		print("Failed to open PCK file for writing:", temp_pck_path)
		return
	file.store_buffer(body)
	file.close()

	# Mount PCK
	if not 
		print("Failed to mount PCK:", temp_pck_path)
		return
	print("✅ PCK mounted:", temp_pck_path)

	# Load all resources inside the mounted PCK
	_load_tres_from_dir("res://temp_files")

	# Clean up after loading
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists("%s.pck" % current_package_id):
		dir.remove("%s.pck" % current_package_id)

func _load_tres_from_dir(path):
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		print(filename)
		if filename.begins_with("."):
			filename = dir.get_next()
			continue
		var full_path = "%s/%s" % [path, filename]
		if dir.current_is_dir():
			_load_tres_from_dir(full_path)
		elif filename.ends_with(".tres"):
			var res = ResourceLoader.load(full_path)
			if res:
				package_data[filename] = res
				print("Loaded:", filename)
		filename = dir.get_next()
	dir.list_dir_end()
