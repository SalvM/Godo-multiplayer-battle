extends Control

signal log_status(new_status)

onready var statusLabel = $Status
onready var roomPopup = $CenterContainer/RoomPopup
onready var rooms = $CenterContainer/RoomPopup/Rooms
onready var players = $CenterContainer/RoomPopup/Rooms/Players
onready var youLabel = $CenterContainer/RoomPopup/Rooms/Players/You
onready var RoomSelector = preload("res://scenes/RoomSelector.tscn")

func clear_players_label():
	for labels in players.get_children():
		if labels.name != "You":
			labels.queue_free()

func _ready():
	Server.connect("log_status", self, "_on_new_log_status")
	Server.connect("refresh_match_rooms", self, "_on_refresh_match_rooms")

func _on_new_log_status(new_status: String):
	statusLabel.text = new_status

func _on_refresh_match_rooms(_match_rooms):
	for match_room in _match_rooms:
		if rooms.has_node(match_room.id):
			rooms.get_node(match_room.id).refresh_selector(match_room)
		else:
			var new_room = RoomSelector.instance()
			new_room.set_name(match_room.id)
			rooms.add_child(new_room)
			new_room.refresh_selector(match_room)

func _on_JoinBtn_pressed():
	Server.connect_to_server_with_websocket()
	roomPopup.show()

func _on_ExitBtn_pressed():
	Server.disconnect_from_server()
	roomPopup.hide()
	clear_players_label()

func _on_JoinRoomBtn_pressed():
	Server.fetch_user_join_room(0)
