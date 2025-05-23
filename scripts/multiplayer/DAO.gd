extends RefCounted
class_name DAO

var db
var table

# Called when the node enters the scene tree for the first time.
func _init():
	if is_server(): 
		db = SQLite.new()
		db.path = "res://data.db"
		db.open_db()
		
		table = {
			"id" : {"data_type": "int", "primary_key" : true, "not_null" : true, "auto_increment"  : true},
			"name": {"data_type" : "text"},
			"password" : {"data_type" : "text"},
			"salt" :{"data_type" : "int", "not_null" : true},
			"health":{"data_type" : "int"},
			"hunger":{"data_type" : "float"},
			"Position_x":{"data_type": "float"},
			"Position_y":{"data_type": "float"},
			"Position_z":{"data_type": "float"},
			"Inventory":{"data_type": "String"},
			"Hotbar":{"data_type": "String"},
			"item_data": {"data_type": "String"}
		}
		
		db.create_table("players", table)
		pass # Replace with function body.

func InsertUserData(name, password, salt):
	var data = {
		"name" : name,
		"password" : password,
		"salt" : salt,
	}
	db.insert_row("players", data)
	
func change_data(name:String, change_name:String, change):
	#db.update_rows("players", "name = '" + name + "'", {"health":10})
	db.update_rows("players", "name = '" + name + "'", {change_name:change})

func GetUserFromDB(username):
	var query = "SELECT salt, password, id, health, hunger, Position_x,Position_y,Position_z, Inventory, Hotbar, item_data from players where name = ?"
	var paramBindings = [username]
	db.query_with_bindings(query, paramBindings)
	#print( db.query_result)
	for i in db.query_result:
		return{
			"id" : i["id"],
			"hashedPassword" : i["password"],
			"salt" : i["salt"],
			"name" : username,
			"health":  i["health"],
			"hunger": i["hunger"],
			"Position_x": i["Position_x"],
			"Position_y": i["Position_y"],
			"Position_z": i["Position_z"],
			"Inventory": i["Inventory"],
			"Hotbar": i["Hotbar"],
			"item_data": i["item_data"]
		}
		
		
static func is_server() -> bool:
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return "--server" in args
