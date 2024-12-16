extends Node
class_name ServerHost

const PORT = 1234
const MAX_CLIENTS = 32

@export var server: GameServer

static var scene: ServerHost
var peer := ENetMultiplayerPeer.new()

func _ready():
	scene = self
	
	peer.create_server(PORT, MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(func(id: int) -> void: 
		var client := RemoteClientConnection.new()
		client.peer_id = id
		
		server.connect_client(client)
	)
