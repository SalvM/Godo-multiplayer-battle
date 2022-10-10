extends Control

onready var RoomLabel = $TitleContainer/RoomLabel
onready var JoinRoomBtn = $JoinRoomBtn
onready var ExitRoomBtn = $ExitRoomBtn
onready var body = $BodyContainer
onready var center = $BodyContainer/Center
onready var players = $BodyContainer/Center/Players
onready var youLabel = $BodyContainer/Center/Players/You

var max_players = 2

func disable_join_button():
	JoinRoomBtn.disabled = true

func close():
	body.visible = false
	self.rect_size.y = 28

func expand():
	self.rect_size.y = 200
	center.rect_size.x = 200
	center.rect_size.y = 72
	center.rect_position.y = 0
	center.margin_top = 28
	body.visible = true
	

func join():
	pass

func exit():
	pass

func clear_players_label():
	for labels in players.get_children():
		if labels.name != "You":
			labels.queue_free()

func refresh_selector(room_status):
	RoomLabel.text = "Room #" + room_status.id + " (" + room_status.players.size() + "/" + max_players + ")"
	if room_status.status != "WAITING":
		disable_join_button()
	for player_id in room_status.players:
		var new_label = youLabel.duplicate()
		new_label.set_name(str(player_id))
		new_label.text = "#" + str(player_id)
		if player_id == get_tree().get_network_unique_id():
			new_label.text += " (You)"
		new_label.visible = true
		players.add_child(new_label)

func _ready():
	expand()
	close()
