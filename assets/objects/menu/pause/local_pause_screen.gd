extends PauseScreen
class_name LocalPauseScreen

@export var local_scene: LocalGameScene
@export var host_on_network_button: Button

func _on_host_on_network_button_button_down() -> void:
	local_scene.host_on_network()
	host_on_network_button.disabled = true
