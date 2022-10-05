extends Node2D

onready var Puppet = preload("res://scenes/Knight.tscn")

var last_world_update = 0
var interpolation_offset = 100 # in milliseconds
var world_state_buffer = []

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

"""
Interpolation helps the client to look smoother.
Most game servers has a status refresh of 20 FPS which is a good standard.
We have an array of world_state(s) ordered from the older to the newest.
The function will use only the first newest state (index 1), which will take
the place of the older (index 0).
This way you can use a lerp function to move the sprites smoothly.
"""
func handle_interpolation_buffer():
	var render_time = OS.get_system_time_msecs() - interpolation_offset
	if world_state_buffer.size() > 1:
		while world_state_buffer.size() > 2 and render_time > world_state_buffer[1]["T"]:
			world_state_buffer.remove(0) # previously calculated, so it can be removed safely
		var old_state = world_state_buffer[0]
		var first_new_state = world_state_buffer[1]
		var interpolation_factor = float(render_time - old_state["T"]) / float(first_new_state["T"] - old_state["T"])
		for player_id in first_new_state.keys():
			if str(player_id) == "T":
				continue
			if player_id == player_unique_id: # it will spawn the player's puppet if needed
				if !player_has_spawned:
					player_has_spawned = true
					spawn_puppet(player_id, first_new_state[player_id]["P"])
				continue
			if not old_state.has(player_id): # the player is no longer connected
				continue
			if get_node("OtherPlayers").has_node(str(player_id)):
				var new_position = lerp(old_state[player_id]["P"], first_new_state[player_id]["P"], interpolation_factor)
				get_node("OtherPlayers/" + str(player_id)).move_puppet(new_position)
			else:
				spawn_puppet(player_id, first_new_state[player_id]["P"])

func update_world_state(world_state):
	# Buffer
	# Interpolation
	# Extrapolation
	# Rubber Banding
	if world_state["T"] > last_world_update:
		last_world_update = world_state["T"]
		world_state_buffer.append(world_state)

func _ready():
	player_unique_id = get_tree().get_network_unique_id()

func _physics_process(delta):
	handle_interpolation_buffer()
