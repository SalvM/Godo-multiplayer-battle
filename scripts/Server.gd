extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909
var match_room = {
	"status": "waiting",
	"players": {}
}

signal log_status(new_status)
signal refresh_room_status(new_status)

func connect_to_server():
	var connection_server = ip + ":" + str(port)
	emit_signal("log_status", "Connecting to " + connection_server + " ...")
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	printt("Connected at port", port)
	emit_signal("log_status", "Successfully connected!")

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

func disconnect_from_server():
	network.close_connection()
	get_tree().network_peer = null
	emit_signal("log_status", "Disconnected from the server")	

remote func return_room_status(room_status):
	printt("return_room_status", room_status)
	match_room = room_status
	emit_signal("refresh_room_status", room_status)

remote func fetch_user_join_room():
	rpc_id(1, "fetch_user_join_room")
	
remote func user_load_battlefield(peer_id):
	get_tree().change_scene("res://scenes/BattleField.tscn")

func send_player_state(player_state):
	rpc_unreliable_id(1, "receive_player_state", player_state)

remote func receive_world_state(world_state):
	var battlefield_node = get_tree().get_root().get_node("BattleField")
	if battlefield_node:
		battlefield_node.update_world_state(world_state)

func fetch_player_damage(requester_instance_id):
	rpc_id(1, "fetch_player_damage", requester_instance_id)

remote func return_player_damage(s_damage: int, requester_instance_id):
	instance_from_id(requester_instance_id).damage(s_damage)

func _ready():
	pass

func _on_peer_connected(peer_id):
	print("User #" + str(peer_id) + " connected")

func _on_peer_disconnected(peer_id):
	print("User #" + str(peer_id) + " disconnected")
	if peer_id == get_tree().get_network_unique_id():
		emit_signal("log_status", "Disconnected from the server")
