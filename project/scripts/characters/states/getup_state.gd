class_name GetUpState
extends PlayerState

var timer: float = 0.0
const GETUP_DURATION := 0.4
const INVINCIBLE_DURATION := 1.0  # 起き上がり後の無敵時間


func enter() -> void:
	timer = 0.0
	player.is_invincible = true
	player.sprite.play("idle")


func exit() -> void:
	# 起き上がり後も短時間無敵を維持（タイマーで解除）
	_start_invincibility_timer()


func physics_update(delta: float) -> void:
	timer += delta
	if timer >= GETUP_DURATION:
		state_machine.transition_to("idle")


func _start_invincibility_timer() -> void:
	var tween := player.create_tween()
	tween.tween_callback(func(): player.is_invincible = false).set_delay(INVINCIBLE_DURATION)
