class_name EnemyIdleState
extends EnemyState

var wait_timer: float = 0.0
const IDLE_DURATION := 0.5


func enter() -> void:
	wait_timer = 0.0
	if enemy.sprite:
		enemy.sprite.play("idle")
	enemy.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	wait_timer += delta
	if wait_timer >= IDLE_DURATION:
		if enemy.target and enemy.get_distance_to_target() <= enemy.detection_range:
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("wander")
