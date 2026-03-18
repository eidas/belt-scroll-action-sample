class_name EnemyChaseState
extends EnemyState


func enter() -> void:
	if enemy.sprite:
		enemy.sprite.play("walk") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("walk") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	if not enemy.target:
		state_machine.transition_to("idle")
		return

	# 攻撃射程に入ったら攻撃位置取りへ
	if enemy.is_in_attack_range():
		state_machine.transition_to("positioning")
		return

	# ターゲットに向かって移動
	var direction := enemy.get_direction_to_target()
	enemy.velocity = direction * enemy.move_speed
	enemy.move_and_slide()
	enemy.update_facing()
