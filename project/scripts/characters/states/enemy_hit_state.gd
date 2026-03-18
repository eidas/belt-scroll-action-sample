class_name EnemyHitState
extends EnemyState

var stun_timer: float = 0.0
const HITSTUN_DURATION := 0.3


func enter() -> void:
	stun_timer = 0.0
	enemy.hitbox_deactivate()
	if enemy.sprite:
		enemy.sprite.play("hit") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("hit") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	stun_timer += delta
	enemy.velocity = enemy.velocity.lerp(Vector2.ZERO, 0.15)
	enemy.move_and_slide()

	if stun_timer >= HITSTUN_DURATION:
		if enemy.is_dead():
			state_machine.transition_to("dead")
		else:
			state_machine.transition_to("chase")
