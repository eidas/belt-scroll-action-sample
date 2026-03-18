class_name DeadState
extends PlayerState

var timer: float = 0.0
const DEATH_DELAY := 1.5  # 残機処理までの待機時間


func enter() -> void:
	timer = 0.0
	player.sprite.play("down") if player.sprite.sprite_frames and player.sprite.sprite_frames.has_animation("down") else player.sprite.play("idle")
	player.velocity = Vector2.ZERO
	player.hitbox_deactivate()


func physics_update(delta: float) -> void:
	timer += delta
	if timer >= DEATH_DELAY:
		_handle_death()


func _handle_death() -> void:
	player.lives -= 1
	if player.lives > 0:
		# リスポーン
		player.hp = player.character_data.max_hp if player.character_data else 100
		player.is_invincible = true
		state_machine.transition_to("getup")
	else:
		# ゲームオーバー（GameManager に通知）
		GameManager.change_state(GameManager.GameState.GAMEOVER)
