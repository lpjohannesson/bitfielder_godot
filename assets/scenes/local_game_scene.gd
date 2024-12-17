extends Node2D
class_name LocalGameScene

@export var local_server: GameServer

var client := LocalClientConnection.new()
var server := LocalServerConnection.new()

func _ready() -> void:
	# Attach local client and server connections
	GameScene.instance.server = server
	server.client = client
	
	local_server.connect_client(client)
