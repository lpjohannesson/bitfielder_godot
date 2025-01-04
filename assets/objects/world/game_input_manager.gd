extends Node
class_name GameInputManager

@export var scene: GameScene

func reset_inputs() -> void:
	if scene.player == null:
		return
	
	scene.player.player_input.reset_inputs()
	
	scene.server.send_packet(GamePacket.create_packet(
		Packets.ClientPacket.RESET_INPUTS,
		null
	))

func read_inputs() -> void:
	if scene.paused:
		return
	
	if scene.player == null:
		return
	
	var input_map := scene.player.player_input.input_map
	
	for action in PlayerInput.PLAYER_ACTIONS:
		if Input.is_action_just_pressed(action):
			input_map[action] = true
			
			var packet := GamePacket.create_packet(
				Packets.ClientPacket.ACTION_PRESSED,
				action
			)
			
			scene.server.send_packet(packet)
		
		if Input.is_action_just_released(action):
			input_map[action] = false
			
			var packet := GamePacket.create_packet(
				Packets.ClientPacket.ACTION_RELEASED,
				action
			)
			
			scene.server.send_packet(packet)

func _process(_delta: float) -> void:
	read_inputs()
