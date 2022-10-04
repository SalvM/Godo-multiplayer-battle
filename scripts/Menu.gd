extends Control

func _ready():
	pass

func _on_JoinBtn_pressed():
	Server.connect_to_server()
