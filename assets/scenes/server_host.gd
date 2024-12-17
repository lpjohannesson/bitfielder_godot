extends Node
class_name ServerHost

const PORT = 1234
const MAX_CLIENTS = 32

@export var server: GameServer

var connection := ENetConnection.new()

var peer_clients := {}

func _ready():
	connection.create_host_bound("*", PORT, 32)

func _process(_delta: float) -> void:
	while true:
		var event := connection.service()
		var event_type: ENetConnection.EventType = event[0]
		var peer: ENetPacketPeer = event[1]
		
		match event_type:
			ENetConnection.EVENT_NONE:
				break
			
			ENetConnection.EVENT_CONNECT:
				var client := RemoteClientConnection.new()
				client.peer = peer
				peer_clients[peer] = client
				
				server.connect_client(client)
			
			ENetConnection.EVENT_RECEIVE:
				var packet := GamePacket.from_bytes(peer.get_packet())
				server.recieve_packet(packet, peer_clients[peer])
