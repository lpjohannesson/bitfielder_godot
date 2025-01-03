extends Node
class_name ServerHost

const PORT = 1234
const MAX_CLIENTS = 32

@export var server: GameServer

var connection := ENetConnection.new()

var peer_clients := {}

func start_host():
	connection.create_host_bound("*", PORT, 32)

func accept_client(client: RemoteClientConnection, login_info: ClientLoginInfo):
	client.client_accepted = true
	
	client.send_packet(GamePacket.create_packet(
		Packets.ServerPacket.ACCEPT_CONNECTION,
		null
	))
	
	server.connect_client(client, login_info)

func recieve_accepted_packet(packet: GamePacket, client: RemoteClientConnection) -> void:
	server.recieve_packet(packet, client)

func recieve_login_packet(packet: GamePacket, client: RemoteClientConnection) -> void:
	var login_info := ClientLoginInfo.from_data(packet.data)
	
	if login_info == null:
		client.send_packet(GamePacket.create_packet(
			Packets.ServerPacket.REJECT_CONNECTION,
			null))
		
		return
	
	# Check for same version
	var game_version := GameServer.get_game_version()
	
	if login_info.game_version != game_version:
		client.send_packet(GamePacket.create_packet(
			Packets.ServerPacket.WRONG_GAME_VERSION,
			game_version))
		
		return
	
	# Check for existing username
	for other_client in server.clients:
		if other_client.player.username == login_info.username:
			client.send_packet(GamePacket.create_packet(
				Packets.ServerPacket.USERNAME_IN_USE,
				null))
			
			return
	
	accept_client(client, login_info)

func recieve_packet(peer: ENetPacketPeer) -> void:
	var client: RemoteClientConnection = peer_clients[peer]
	var packet := GamePacket.from_bytes(peer.get_packet())
	
	if packet == null:
		return
	
	print(Packets.ClientPacket.find_key(packet.type), ": ", packet.data)
	
	if client.client_accepted:
		recieve_accepted_packet(packet, client)
	else:
		recieve_login_packet(packet, client)

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
			
			ENetConnection.EVENT_DISCONNECT:
				var client: RemoteClientConnection = peer_clients[peer]
				
				server.disconnect_client(client)
				peer_clients.erase(peer)
			
			ENetConnection.EVENT_RECEIVE:
				recieve_packet(peer)
