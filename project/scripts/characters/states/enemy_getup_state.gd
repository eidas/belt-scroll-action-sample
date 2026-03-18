class_name EnemyGetUpState
extends EnemyState

var timer: float = 0.0
const GETUP_DURATION := 0.4


func enter() -> void:
	timer = 0.0
	if enemy.sprite:
		enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	timer += delta
	if timer >= GETUP_DURATION:
		state_machine.transition_to("idle")
