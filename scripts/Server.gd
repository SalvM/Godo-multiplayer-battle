extends Node

const LOCALHOST = "127.0.0.1"
const HOST = "2.tcp.eu.ngrok.io"
const PORT: int = 17282
const RECONNECT_TIMEOUT: float = 3.0
const is_debug = false
var network 

# Used to TCP connections
#const Client = preload("res://TCP.gd")
#var _client: Client = Client.new()

var server_address = ""

var match_room = {
	"status": "waiting",
	"players": {}
}

var client_clock = 0	# time in ms
var decimal_corrector: float = 0
var latency_array = []
var latency = 0			# latency in ms
var delta_latency = 0

var logged_room_id = -1

signal log_status(new_status)
signal refresh_match_rooms(new_status)

func get_connection_status_text(status):
	var connection_result = ""
	match status:
		0:
			connection_result = "The ongoing connection disconnected"
		1:
			connection_result = "A connection attempt is ongoing."
		2:
			connection_result = "The connection attempt succeeded."
	return connection_result

func connect_to_server():
	server_address = LOCALHOST if is_debug else HOST
	emit_signal("log_status", "Connecting to " + server_address + " ...")
	
	# this signals will handle everything.
	network = NetworkedMultiplayerENet.new()
	network.connect("connection_succeeded", self, "_on_connection_succeded")
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("server_disconnected", self, "_on_server_disconnected")
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")
	network.create_client(server_address, PORT)
	emit_signal("log_status", get_connection_status_text(network.get_connection_status()))

func connect_to_server_with_websocket():
	server_address = LOCALHOST if is_debug else HOST
	server_address = server_address + ":" + str(PORT)
	network = WebSocketClient.new()
	network.connect("connection_succeeded", self, "_on_connection_succeded")
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("server_disconnected", self, "_on_server_disconnected")
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")
	
	emit_signal("log_status", "Connecting to " + server_address + " ...")
	var err = network.connect_to_url(server_address, PoolStringArray(), true)
	if err != OK:
		print("Unable to connect %s", server_address)
		emit_signal("log_status", "Unable to connect to the server " + server_address)
		return
	get_tree().network_peer = network
	set_process(true)

func _connect_after_timeout(timeout: float) -> void:
	yield(get_tree().create_timer(timeout), "timeout") # Delay for timeout
	connect_to_server_with_websocket()

func disconnect_from_server():
	network.close_connection()
	get_tree().network_peer = null
	emit_signal("log_status", "Disconnected from the server")	

remote func return_match_room_status(room_status):
	# printt("return_match_room_status", room_status)
	if get_tree().get_network_unique_id() in room_status.players:
		logged_room_id = room_status.id
		match_room = room_status
	emit_signal("refresh_room_status", room_status)

func fetch_user_join_room(room_id):
	rpc_id(1, "fetch_user_join_room", room_id)
	
remote func user_load_battlefield(room_id):
	logged_room_id = int(room_id)
	get_tree().change_scene("res://scenes/BattleField.tscn")

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state, logged_room_id)

remote func receive_room_state(room_state):
	var battlefield_node = get_tree().get_root().get_node("BattleField")
	if battlefield_node:
		battlefield_node.update_world_state(room_state)

# when the player is in the lobby, not in a match
remote func return_match_rooms(match_rooms):
	emit_signal("refresh_match_rooms", match_rooms)
	for match_room in match_rooms:
		return_match_room_status(match_room)

func fetch_player_damage():
	rpc_id(1, "fetch_player_damage", logged_room_id)

func determine_latency():
	rpc_id(1, "determine_latency", OS.get_system_time_msecs())

remote func return_latency(client_time):
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_port = latency_array[4]
		for i in range(latency_array.size() - 1, -1, -1):
			if latency_array[i] > 2 * mid_port and latency_array[i] > 20: # this latency is a spike
				latency_array.remove(i) # we don't need it for calculation
			else:
				total_latency += latency_array[i]
		var average_latency = total_latency / latency_array.size()
		delta_latency = average_latency - latency
		latency = average_latency
		#print("New latency ", latency)
		#print("Delta latency ", delta_latency)
		latency_array.clear()

func fetch_server_time():
	rpc_id(1, "fetch_server_time", OS.get_system_time_msecs())
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "determine_latency")
	self.add_child(timer)

remote func return_server_time(server_time, client_time): # in ms
	latency = (OS.get_system_time_msecs() - client_time) / 2
	client_clock = server_time + latency
	
func _ready():
	pass

func _process(delta):
	if network:
		network.poll()

func _physics_process(delta): #0.01667
	client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	decimal_corrector += (delta * 1000) - int(delta * 1000)
	if decimal_corrector >= 1.00:
		client_clock += 1
		decimal_corrector -= 1.00

func _on_server_disconnected():
	emit_signal("log_status", get_connection_status_text(0))

func _on_connection_failed():
	emit_signal("log_status", get_connection_status_text(0))

func _on_connection_succeded():
	emit_signal("log_status", get_connection_status_text(2))
	get_tree().set_network_peer(network)

func _on_peer_connected(peer_id):
	if peer_id == 1:
		print("Successfully connected to the server")
		emit_signal("log_status", "Successfully connected to the server")
		fetch_server_time()

func _on_peer_disconnected(peer_id):
	if peer_id == get_tree().get_network_unique_id():
		print("disconnected ", peer_id)
		emit_signal("log_status", "Disconnected from the server")
