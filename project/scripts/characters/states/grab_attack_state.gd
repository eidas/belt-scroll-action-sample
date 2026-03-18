class_name GrabAttackState
extends PlayerState

var attack_timer: float = 0.0
const ATTACK_DURATION := 0.3


func enter() -> void:
	attack_timer = 0.0
	player.sprite.play("attack1")
	player.hitbox_activate()


func exit() -> void:
	player.hitbox_deactivate()


func physics_update(delta: float) -> void:
	attack_timer += delta
	if attack_timer >= ATTACK_DURATION:
		state_machine.transition_to("grab")
