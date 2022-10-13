extends Control

onready var RoomLabel = $TitleContainer/RoomLabel
onready var JoinRoomBtn = $ButtonContainer/JoinRoomBtn
onready var ExitRoomBtn = $ButtonContainer/ExitRoomBtn
onready var body = $BodyContainer
onready var center = $BodyContainer/Center
onready var players = $BodyContainer/Center/Players
onready var youLabel = $BodyContainer/Center/Players/You

var max_players = 2

func disable_join_button():
	JoinRoomBtn.disabled = true

func close():
	self.rect_size.y = 28
	self.rect_min_size.y = 28
	center.rect_size.y = 0
	JoinRoomBtn.visible = true
	ExitRoomBtn.visible = false
	body.visible = false

func expand():
	self.rect_size.y = 100
	self.rect_min_size.y = 100
	center.rect_size.x = 200
	center.rect_size.y = 72
	body.rect_position.y = 28
	# center.margin_top = 28
	body.visible = true
	JoinRoomBtn.visible = false
	ExitRoomBtn.visible = true

func join():
	Server.fetch_user_join_room(self.name)

func exit():
	Server.fetch_user_leave_room(self.name)

func clear_players_label():
	for labels in players.get_children():
		if labels.name != "You":
			labels.queue_free()

func refresh_selector(room_status):
	var room_id = int(room_status.id) + 1
	var connected_players = room_status.players.size()
	RoomLabel.text = "Room #" + str(room_id) + " (" + str(connected_players) + "/" + str(max_players) + ")"
	if room_status.status != "WAITING":
		disable_join_button()
	clear_players_label()
	for player_id in room_status.players:
		var new_label = youLabel.duplicate()
		new_label.set_name(str(player_id))
		new_label.text = "#" + str(player_id)
		if player_id == get_tree().get_network_unique_id():
			new_label.text += " (You)"
		new_label.visible = true
		players.add_child(new_label)
	if get_tree().get_network_unique_id() in room_status.players:
		expand()
	else:
		close()

func _ready():
	close()

func _on_JoinRoomBtn_pressed():
	join()

func _on_ExitRoomBtn_pressed():
	exit()
