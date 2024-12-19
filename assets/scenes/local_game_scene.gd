extends Node2D
class_name LocalGameScene

@export var local_server: GameServer
@export var pause_screen: PauseScreen

var client := LocalClientConnection.new()
var server := LocalServerConnection.new()

func pause_game() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	
	pause_screen.visible = paused

func _ready() -> void:
	# Attach local client and server connections
	GameScene.instance.server = server
	server.client = client
	
	local_server.connect_client(client)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_game()

func _on_pause_screen_continue_selected() -> void:
	pause_game()

func _on_pause_screen_quit_selected() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://assets/scenes/menu_scene.tscn")
