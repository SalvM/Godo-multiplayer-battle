extends Node2D

onready var Puppet = preload("res://scenes/Knight.tscn")

var last_world_update = 0
var player_has_spawned = false
var player_unique_id = 0

func spawn_puppet(peer_id, coordinates):
	var is_player_puppet = peer_id == player_unique_id
	var puppet_instance = Puppet.instance()
	puppet_instance.set_name(str(peer_id))
	puppet_instance.set_network_master(peer_id)
	puppet_instance.fighter_name = "You" if is_player_puppet else "#" + str(peer_id)
	puppet_instance.is_enemy = !is_player_puppet
	puppet_instance.position.x = coordinates.x
	puppet_instance.position.y = coordinates.y
	puppet_instance.scale.x = 2
	puppet_instance.scale.y = 2
	var puppet_node_position = "Player" if is_player_puppet else "OtherPlayers"
	get_tree().get_root().get_node("BattleField/" + puppet_node_position).add_child(puppet_instance)

func despawn_player(player_id):
	var players_node = get_tree().get_root().get_node("BattleField/OtherPlayers")
	var puppet_instance = players_node.get_node(str(player_id))
	players_node.remove_child(puppet_instance)
	puppet_instance.queue_free()

func update_world_state(world_state):
	# Buffer
	# Interpolation
	# Extrapolation
	# Rubber Banding
	if !player_has_spawned:
		player_has_spawned = true
		spawn_puppet(player_unique_id, world_state[player_unique_id]["P"])
	if world_state["T"] > last_world_update:
		last_world_update = world_state["T"]
		world_state.erase("T")
		world_state.erase(player_unique_id)
		for player_id in world_state.keys():
			if get_node("OtherPlayers").has_node(str(player_id)):
				get_node("OtherPlayers/" + str(player_id)).move_puppet(world_state[player_id]["P"])
			else:
				spawn_puppet(player_id, world_state[player_id]["P"])

func _ready():
	player_unique_id = get_tree().get_network_unique_id()
