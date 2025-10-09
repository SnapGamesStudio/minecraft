extends Control

@export var scene: PackedScene
@export var loading_bar: ProgressBar

func _ready() -> void:
	ItemDownloader.completed_download.connect(start_scene)
	Backend.playerdata_updated.connect(download_items)

func _process(delta):
	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	
func start_scene() -> void:
	get_tree().call_deferred("change_scene_to_packed", scene)
	pass
	
func download_items():
	ItemDownloader.fetch_all_jsons()
	
