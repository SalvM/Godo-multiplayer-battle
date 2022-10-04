extends Control

signal log_status(new_status)

onready var statusLabel = $Status
onready var roomPopup = $CenterContainer/RoomPopup
onready var players = $CenterContainer/RoomPopup/VBoxContainer/Players
onready var youLabel = $CenterContainer/RoomPopup/VBoxContainer/Players/You

func clear_players_label():
	for labels in players.get_children():
		if labels.name != "You":
			labels.queue_free()

func _ready():
	Server.connect("log_status", self, "_on_new_log_status")
	Server.connect("refresh_room_status", self, "_on_room_status_refresh")

func _on_new_log_status(new_status: String):
	statusLabel.text = new_status

func _on_room_status_refresh(new_status):
	var new_players = new_status.players
	youLabel.visible = false
	
	clear_players_label()
	
	for player_id in new_players:
		var new_label = youLabel.duplicate()
		new_label.set_name(str(player_id))
		new_label.text = "#" + str(player_id)
		if player_id == get_tree().get_network_unique_id():
			new_label.text += " (You)"
		new_label.visible = true
		players.add_child(new_label)
	
func _on_JoinBtn_pressed():
	Server.connect_to_server()
	roomPopup.show()

func _on_ExitBtn_pressed():
	Server.disconnect_from_server()
	roomPopup.hide()
	clear_players_label()

func _on_JoinRoomBtn_pressed():
	Server.fetch_user_join_room()
