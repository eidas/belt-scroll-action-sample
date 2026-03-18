class_name EnemyAttackState
extends EnemyState

var attack_timer: float = 0.0
const ATTACK_DURATION := 0.4
const HITBOX_START := 0.1
const HITBOX_END := 0.3


func enter() -> void:
	attack_timer = 0.0
	enemy.velocity = Vector2.ZERO
	enemy.update_facing()
	if enemy.sprite:
		enemy.sprite.play("attack1") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("attack1") else enemy.sprite.play("idle")


func exit() -> void:
	enemy.hitbox_deactivate()
	enemy.start_cooldown()
	# 攻撃枠を解放
	var managers := enemy.get_tree().get_nodes_in_group("attack_manager")
	for m in managers:
		if m is EnemyAttackManager:
			m.release_attack_slot(enemy)


func physics_update(delta: float) -> void:
	attack_timer += delta

	if attack_timer >= HITBOX_START and attack_timer < HITBOX_END:
		enemy.hitbox_activate()
	elif attack_timer >= HITBOX_END:
		enemy.hitbox_deactivate()

	if attack_timer >= ATTACK_DURATION:
		state_machine.transition_to("chase")
