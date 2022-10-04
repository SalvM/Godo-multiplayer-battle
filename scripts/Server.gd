extends Node

onready var Puppet = preload("res://scenes/Knight.tscn")

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909
var max_players = 4

func connect_to_server():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	printt("Connected at port", port)
	
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

func disconnect_from_server():
	get_tree().network_peer = null

remote func user_load_battlefield(peer_id):
	printt('user_load_battlefield', peer_id)
	get_tree().change_scene("res://scenes/BattleField.tscn")

remote func user_spawn_puppet(peer_id, x_coordinates, is_player_puppet):
	var puppet_instance = Puppet.instance()
	puppet_instance.set_name(str(peer_id))
	puppet_instance.set_network_master(peer_id)
	puppet_instance.fighter_name = "You" if  peer_id == get_tree().get_network_unique_id() else "#"+str(peer_id)
	puppet_instance.position.x = x_coordinates
	puppet_instance.position.y = 30
	puppet_instance.scale.x = 2
	puppet_instance.scale.y = 2
	get_tree().get_root().get_node("BattleField").add_child(puppet_instance)

func fetch_battlefield_loaded():
	rpc_id(1, "fetch_battlefield_loaded")

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
