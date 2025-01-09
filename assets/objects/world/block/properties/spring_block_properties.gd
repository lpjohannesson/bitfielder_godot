extends BlockProperties
class_name SpringBlockProperties

@export var spring_sound: AudioStream

const SPRING_VELOCITY = 220.0

func block_entity_collision(entity: GameEntity, collision: KinematicCollision2D) -> void:
	if entity.player != null and entity.player.player_state == Player.PlayerState.CLIMBING:
		return
	
	entity.body.velocity.y = -SPRING_VELOCITY
	
	if entity.on_server:
		var block_position: Vector2i = collision.get_collider_shape().block_position
		var sound_position := GameServer.instance.world.blocks.block_to_world(block_position, true)
		
		GameServer.instance.spawn_world_sound("spring", sound_position)
