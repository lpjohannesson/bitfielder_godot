class_name Packets

enum ServerPacket {
	ACCEPT_CONNECTION,
	REJECT_CONNECTION,
	USERNAME_IN_USE,
	WRONG_GAME_VERSION,
	SERVER_CLOSED,
	CREATE_BLOCK_CHUNK,
	PLAYER_CHUNK_INDEX,
	UPDATE_BLOCK,
	CREATE_LIGHT_HEIGHTMAP,
	CREATE_ENTITY,
	DESTROY_ENTITY,
	ENTITY_DATA,
	ASSIGN_PLAYER,
	CREATE_INVENTORY,
	CHANGE_PLAYER_SKIN,
	PLAY_ENTITY_SOUND,
	PLAY_WORLD_SOUND
}

enum ClientPacket {
	LOGIN_INFO,
	QUIT_SERVER,
	ACTION_PRESSED,
	ACTION_RELEASED,
	RESET_INPUTS,
	CHECK_PLAYER_POSITION,
	CHECK_BLOCK_UPDATE,
	SELECT_ITEM,
	USE_CURSOR_ITEM,
	CHANGE_SKIN
}
