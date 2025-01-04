class_name PlayerInput

const PLAYER_ACTIONS := [
	"move_left",
	"move_right",
	"look_up",
	"look_down",
	"jump",
	"use_front",
	"use_back",
	"interact"
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

func set_action(action: String, value: bool) -> void:
	if not action in input_map:
		return
	
	input_map[action] = value

func reset_inputs() -> void:
	for action in PLAYER_ACTIONS:
		input_map[action] = false

func _init() -> void:
	for action in PLAYER_ACTIONS:
		input_map[action] = false
		last_input_map[action] = false
