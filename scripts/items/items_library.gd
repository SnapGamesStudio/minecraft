extends Resource
class_name ItemsLibrary

@export var items_array: Array[ItemBase]

var block_items:Array[ItemBlock]
var items: Dictionary = {}
var types:Array = []

func init_items():
	for item in items_array:
		if item is ItemBlock:
			block_items.append(item)
		
		items[item.unique_name] = item
		types.append(item.unique_name)

func get_item(unique_name: StringName) -> ItemBase:
	if not items.has(unique_name):
		push_error("Item with unique name '%s' does not exist in the library." % unique_name)
		return null
	return items[unique_name]
