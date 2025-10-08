extends Control

@onready var checks: Timer = $Checks

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_scene: PackedScene
@export var loading_bar: ProgressBar

var package_ids:Array
var sent_requests:int = 0

signal checked_for_item
var has_item = false

func _ready() -> void:
	
	#if Connection.is_server():
		#start_scene()
		#return

	#else:
		#pass
		#start_scene()
		
	Backend.playerdata_updated.connect(download_items)

func _process(delta):
	if Input.is_action_just_pressed("0"):
		$Slot.item = ItemDownloader.load_encrypted_tres("dirt.tres")
		$Slot.update_slot()
	
	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	
	
	

func start_scene() -> void:
	get_tree().call_deferred("change_scene_to_packed", multiplayer_scene)
	pass
	
func download_items():
	ItemDownloader.get_packages(Callable(self,"packages_request_completed"))
	
	


func _on_checks_timeout() -> void:
	if sent_requests == ItemDownloader.fnished_requests:
		start_scene()
	print(sent_requests," ",ItemDownloader.fnished_requests)

func packages_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		push_error("Failed to get packages list: %s" % response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) == TYPE_DICTIONARY and data.has("packages"):
		var ids = data["packages"]
		package_ids = ids
		print("📦 Available package IDs:", ids)
		for id in ids:
			sent_requests += 1
			ItemDownloader.download_package(id)
			
		checks.start()
	else:
		push_warning("Unexpected response format")
