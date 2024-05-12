extends Node

# The URL we will connect to.
var client: ConvexGd
var server_url: String
var websocket_url = "ws://localhost:9080"
var socket := WebSocketPeer.new()

signal message_received(txt)
signal update_mental_goal(data)
signal update_pddl_goal(data)
signal debug_mood_summary_received(txt)
signal update_npc_thought(data)


func log_message(message):
	var time = "[color=#aaaaaa] %s [/color]" % Time.get_time_string_from_system()
	print(time + " " + message)

func process_packet(pkt):
	# parse the message
	var json = JSON.new()
	json.parse(pkt)
	var data = json.get_data()
	if data["type"] == "message":
		emit_signal("message_received", data)
	elif data["type"] == "store_memory_success":
		log_message("Memory stored successfully")
	elif data["type"] == "new_goal":
		emit_signal("update_mental_goal", data)
	elif data["type"] == "pddl_problem":
		emit_signal("update_pddl_goal", data)
	elif data["type"] == "debug_determine_mood":
		emit_signal("debug_mood_summary_received", data)
	elif data["type"] == "npc_message_thought_txt":
		emit_signal("update_npc_thought", data)
	else:
		log_message("Unknown message type: %s" % data["type"])
		log_message(data)
	

func _ready():
	if socket.connect_to_url(websocket_url) != OK:
		log_message("Unable to connect.")
		set_process(false)


func _process(_delta):
	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			process_packet(socket.get_packet().get_string_from_ascii())


func _exit_tree():
	socket.close()


func _on_button_ping_pressed():
	# test for storing memory
	var params = {
		'gameId': Game.id,
		'authorId': 'LLM',
		'content': 'You have grown annoyed of Helios, he treats you as a tool without any concern for your feelings.',
		'type': 'relationship',
		'relatedMemoryIds': [],
		'relatedAgentIds': ['player'],
		'game_time': GlobalTime.game_time,
	}
	socket.send_text(JSON.stringify({
		"action": "store_memory",
		"payload": params,
	}))

func send_message(txt):
	socket.send_text(txt)
