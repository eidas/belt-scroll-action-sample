class_name IdleState
extends PlayerState


func enter() -> void:
	player.velocity = Vector2.ZERO
	player.sprite.play("idle")


func physics_update(delta: float) -> void:
	var pi := player.player_index

	# 必殺技（最優先）
	if InputManager.is_special_input(pi):
		state_machine.transition_to("special")
		return

	# 攻撃
	if InputManager.is_action_just_pressed(pi, "attack"):
		state_machine.transition_to("attack")
		return

	# ジャンプ
	if InputManager.is_action_just_pressed(pi, "jump"):
		state_machine.transition_to("jump")
		return

	# ダッシュ検知
	if InputManager.check_dash_input(pi, "left") or InputManager.check_dash_input(pi, "right"):
		state_machine.transition_to("dash")
		return

	# 移動
	var direction := InputManager.get_movement_vector(pi)
	if direction != Vector2.ZERO:
		state_machine.transition_to("walk")
		return
