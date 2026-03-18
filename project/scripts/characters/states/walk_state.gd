class_name WalkState
extends PlayerState


func enter() -> void:
	player.sprite.play("walk")


func physics_update(delta: float) -> void:
	var pi := player.player_index

	# 必殺技
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
	if direction == Vector2.ZERO:
		state_machine.transition_to("idle")
		return

	player.apply_movement(direction, player.character_data.move_speed, delta)
