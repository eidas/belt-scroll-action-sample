class_name EnemyDeadState
extends EnemyState

var timer: float = 0.0
const DEATH_DELAY := 0.5


func enter() -> void:
	timer = 0.0
	enemy.hitbox_deactivate()
	enemy.velocity = Vector2.ZERO
	if enemy.sprite:
		enemy.sprite.play("down") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("down") else enemy.sprite.play("idle")

	# スコア加算（撃破したプレイヤーの特定は簡略化して1Pに加算）
	ScoreManager.add_enemy_score(0, enemy.score_type)

	# 攻撃枠を解放
	var managers := enemy.get_tree().get_nodes_in_group("attack_manager")
	for m in managers:
		if m is EnemyAttackManager:
			m.release_attack_slot(enemy)


func physics_update(delta: float) -> void:
	timer += delta
	if timer >= DEATH_DELAY:
		# TODO: アイテムドロップ判定（Phase 7）
		enemy.queue_free()
