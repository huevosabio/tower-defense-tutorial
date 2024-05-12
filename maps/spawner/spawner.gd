class_name Spawner
extends Node2D

signal countdown_started(seconds: float)
signal wave_started(current_wave: int)
signal enemy_spawned(enemy: Enemy)
signal enemies_defeated

@export_range(0.5, 5.0, 0.5) var spawn_rate: float = 2.0
@export var wave_count: int = 3
@export var enemies_per_wave_count: int = 10
@export var spawn_probabilities := {
	"infantry": 50,
	"infantry2": 30,
	"tank": 20,
	"helicopter": 5,
}

var enemy_scenes := {
	"infantry": preload("res://entities/enemies/infantry/infantry_t1.tscn"),
	"infantry2": preload("res://entities/enemies/infantry/infantry_t2.tscn"),
	"tank": preload("res://entities/enemies/tanks/tank.tscn"),
	"helicopter": preload("res://entities/enemies/helicopters/helicopter.tscn"),
	"generic": preload("res://entities/enemies/generic/generic.tscn")
}

var spawn_locations := []
var current_wave := 0
var current_enemy_count := 0
var _enemy_removed_count := 0
var latest_move_func := ""
var latest_texture

@onready var wave_timer := $WaveTimer as Timer
@onready var spawn_timer := $SpawnTimer as Timer
@onready var spawn_container := $SpawnContainer as Node2D

func _ready() -> void:
	for marker in spawn_container.get_children():
		spawn_locations.append(marker)
	wave_timer.start()
	await owner.ready
	countdown_started.emit(wave_timer.time_left)


func _start_wave():
	current_wave += 1
	spawn_timer.start()
	current_enemy_count = 0
	wave_started.emit(current_wave)


func _end_wave():
	if current_wave < wave_count:
		wave_timer.start()
		countdown_started.emit(wave_timer.time_left)


func _spawn_new_enemy(enemy_name: String):
	get_latest_creature()

func _finish_spawn_new_enemy():
	var enemy = enemy_scenes["generic"].instantiate()
	var enemy_script = compile_custom_enemy(latest_move_func)
	enemy.set_script(enemy_script)
	get_parent().add_child(enemy)
	var spawn_marker = spawn_locations.pick_random()
	enemy.global_position = spawn_marker.global_position
	current_enemy_count += 1
	enemy_spawned.emit(enemy)
	print('spawned an enemy')
	enemy.enemy_removed.connect(_on_enemy_removed)
	enemy.set_sprite(latest_texture)

func _on_wave_timer_timeout() -> void:
	_start_wave()

func _on_spawn_timer_timeout() -> void:
	if current_enemy_count < enemies_per_wave_count:
		_spawn_new_enemy(_pick_enemy())
		var spawn_delay := randf_range(spawn_rate / 2, spawn_rate)
		spawn_timer.start(spawn_delay)
	else:
		_end_wave()


func _pick_enemy() -> String:
	var tot_probability: int = 0
	for key in spawn_probabilities.keys():
		tot_probability += spawn_probabilities[key]
	var rand_number = randi_range(0, tot_probability - 1)
	var enemy_name: String
	for key in spawn_probabilities.keys():
		if rand_number < spawn_probabilities[key]:
			enemy_name = key
			break
		rand_number -= spawn_probabilities[key]
	return enemy_name


func _on_enemy_removed():
	_enemy_removed_count += 1
	if _enemy_removed_count == wave_count * enemies_per_wave_count:
		enemies_defeated.emit()


func compile_custom_enemy(custom_move_func):
	var enemyName = "Cat"
	var harness = "class_name " + enemyName + """
extends Enemy

func set_sprite(texture):
	var texture_rect = TextureRect.new()
	add_child(texture_rect)
	texture_rect.texture = texture
	print("set it")
"""
	var scriptInput = harness + custom_move_func
	var script = GDScript.new()
	script.set_source_code(scriptInput)
	script.reload()
	return script


func get_latest_creature():
	var http_request = HTTPRequest.new() # Create a new HTTPRequest node if it's not already attached.
	add_child(http_request) # Add it as a child if not already in the scene tree.
	http_request.request_completed.connect(_on_request_completed)
	# Define your JSON data to send
	var data_to_send = {
		"path": "creatures:getCreature",
		"args": {},
		"format": "json"
	}
	var json = JSON.stringify(data_to_send)
	var headers = ["Content-Type: application/json"]
	var url = "https://strong-ox-148.convex.cloud/api/query"
	http_request.request(url, headers, HTTPClient.METHOD_POST, json)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	latest_move_func = json.value.moveFunc
	var imgUrl = json.value.imgUrl
	print(latest_move_func)
	print(imgUrl)
	var http_img_request = HTTPRequest.new() # Create a new HTTPRequest node if it's not already attached.
	add_child(http_img_request) # Add it as a child if not already in the scene tree.
	http_img_request.request_completed.connect(_finish_set_image)
	http_img_request.request(imgUrl)

func _finish_set_image(result, response_code, headers, body):
	#print("got image")
	#var image = Image.new()
	#var local_img = load("res://assets/enemies/helicopter/tier1/body_die_00.png")
	#var error = image.load_png_from_buffer(body)
	#var texture = ImageTexture.new()
	#texture.create_from_image(image)
	#latest_texture = texture
	#latest_texture = load("res://assets/enemies/helicopter/tier1/body_die_00.png")
	_finish_spawn_new_enemy()
