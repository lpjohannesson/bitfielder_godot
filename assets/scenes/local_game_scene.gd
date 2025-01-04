extends Node2D
class_name LocalGameScene

@export var scene: GameScene

@export var local_server: GameServer
@export var pause_screen: PauseScreen

var client := LocalClientConnection.new()
var server := LocalServerConnection.new()
var server_host: ServerHost

func host_on_network() -> void:
	if server_host != null:
		return
	
	server_host = ServerHost.new()
	add_child(server_host)
	
	server_host.server = local_server
	server_host.start_host()
	
	get_tree().paused = false

func pause_game() -> void:
	pause_screen.pause_game()
	
	if server_host == null:
		get_tree().paused = scene.paused

func _ready() -> void:
	# Attach local client and server connections
	scene.server = server
	server.client = client
	
	var login_info := ClientLoginInfo.new()
	login_info.username = "Player"
	
	local_server.connect_client(client, login_info)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_game()

func _exit_tree() -> void:
	scene.quit_server()
	local_server.close_server()
	
	if server_host != null:
		server_host.connection.service()

func _on_local_pause_screen_continue_selected() -> void:
	pause_game()
