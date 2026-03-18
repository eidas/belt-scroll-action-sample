class_name EnemyKnockdownState
extends EnemyState

var timer: float = 0.0
const DOWN_DURATION := 0.8


func enter() -> void:
	timer = 0.0
	enemy.hitbox_deactivate()
	if enemy.sprite:
		enemy.sprite.play("down") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("down") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	timer += delta
	enemy.velocity = enemy.velocity.lerp(Vector2.ZERO, 0.15)
	enemy.move_and_slide()

	if timer >= DOWN_DURATION:
		if enemy.is_dead():
			state_machine.transition_to("dead")
		else:
			state_machine.transition_to("getup")
