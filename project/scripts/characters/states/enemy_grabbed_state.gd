class_name EnemyGrabbedState
extends EnemyState

## 掴まれ状態: 動けない。振りほどきタイマーで自動解除

var grab_timer: float = 0.0
const STRUGGLE_FREE_TIME := 2.5  # 振りほどきまでの時間


func enter() -> void:
	grab_timer = 0.0
	enemy.velocity = Vector2.ZERO
	enemy.hitbox_deactivate()
	if enemy.sprite:
		enemy.sprite.play("hit") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("hit") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	grab_timer += delta
	if grab_timer >= STRUGGLE_FREE_TIME:
		enemy.release_from_grab()
