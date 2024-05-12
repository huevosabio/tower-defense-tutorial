extends Node

signal money_changed(money: int)

var money: int:
	set(m):
		money = m
		money_changed.emit(money)
var tower_costs: Dictionary

func _ready() -> void:
	var tower_costs_resource = load("res://entities/towers/tower_costs_json.tres")
	tower_costs = tower_costs_resource.data
	_load_env_vars()

func _load_env_vars():
	print("LOADING ENV VARS")
	# hacky way to load local env variable files
	var file = FileAccess.open("res://.env", FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		while file.get_position() < file.get_length():
			var line = file.get_line()
			if line != "" and not line.begins_with("#"):  # Ignore empty lines and comments
				var parts = line.split("=")
				if parts.size() >= 2:
					var key = parts[0]
					var value = "=".join(parts.slice(1, parts.size())) # In case value contains '='
					OS.set_environment(key, value)
		file.close()
	else:
		print("[ERROR] [logger] Failed to open .env file")
