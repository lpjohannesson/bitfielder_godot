class_name PlayerSkinManager

const SKIN_SIZE := Vector2i(32, 16)

static func load_skin_image(skin_bytes: PackedByteArray) -> Image:
	var skin_image := Image.new()
	skin_image.load_png_from_buffer(skin_bytes)
	
	if skin_image.get_size() != SKIN_SIZE:
		return null
	
	return skin_image
	
static func load_skin(player: Player, skin_bytes: PackedByteArray) -> bool:
	var skin_image := load_skin_image(skin_bytes)
	
	if skin_image == null:
		return false
	
	var skin_texture := ImageTexture.create_from_image(skin_image)
	
	var player_sprite := player.entity.sprite
	player_sprite.material.set_shader_parameter("skin_texture", skin_texture)
	
	return true

static func change_skin(player: Player, skin_path: String) -> void:
	var skin_bytes := FileAccess.get_file_as_bytes(skin_path)
	
	if not load_skin(player, skin_bytes):
		return
	
	var packet := GamePacket.create_packet(
		Packets.ClientPacket.CHANGE_SKIN,
		skin_bytes
	)
	
	GameScene.instance.server.send_packet(packet)
