class_name JumpState
extends PlayerState

var _move_direction: Vector2 = Vector2.ZERO


func enter() -> void:
	player.sprite.play("jump")
	var force := 300.0
	if player.character_data:
		force = player.character_data.jump_force
	player.jump(force)
	_move_direction = InputManager.get_movement_vector(player.player_index)


func physics_update(delta: float) -> void:
	# 空中でも移動入力を受け付ける
	_move_direction = InputManager.get_movement_vector(player.player_index)

	var speed := 120.0
	if player.character_data:
		speed = player.character_data.move_speed
	player.apply_movement(_move_direction, speed, delta)

	# 高さ更新
	var landed := player.update_altitude(delta)
	if landed:
		state_machine.transition_to("idle")
		return

	# 空中攻撃
	if InputManager.is_action_just_pressed(player.player_index, "attack"):
		state_machine.transition_to("jumpattack")
