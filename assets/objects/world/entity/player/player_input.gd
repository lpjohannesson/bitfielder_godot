class_name PlayerInput

const PLAYER_ACTIONS := [
	"move_left",
	"move_right",
	"look_up",
	"look_down",
	"jump",
	"break_front",
	"break_back"
]

var last_input_map := {}
var input_map := {}

func is_action_pressed(action: String) -> bool:
	return input_map[action]

func is_action_just_pressed(action: String) -> bool:
	return input_map[action] and !last_input_map[action]

func get_axis(action1: String, action2: String) -> float:
	return float(input_map[action2]) - float(input_map[action1])

func update_inputs() -> void:
	for action in PLAYER_ACTIONS:
		last_input_map[action] = input_map[action]

func read_inputs(server: ServerConnection) -> void:
	for action in PLAYER_ACTIONS:
		if Input.is_action_just_pressed(action):
			input_map[action] = true
			
			var packet := GamePacket.create_packet(
				Packets.ClientPacket.ACTION_PRESSED,
				action
			)
			
			server.send_packet(packet)
		
		if Input.is_action_just_released(action):
			input_map[action] = false
			
			var packet := GamePacket.create_packet(
				Packets.ClientPacket.ACTION_RELEASED,
				action
			)
			
			server.send_packet(packet)

func set_action(action: String, value: bool) -> void:
	if not action in input_map:
		return
	
	input_map[action] = value

func _init() -> void:
	for action in PLAYER_ACTIONS:
		input_map[action] = false
		last_input_map[action] = false
