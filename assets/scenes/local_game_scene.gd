extends Node2D
class_name LocalGameScene

@export var server: GameServer

var client: LocalClientConnection

func _ready() -> void:
	client = LocalClientConnection.new()
	server.connect_client(client)
