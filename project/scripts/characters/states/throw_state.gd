class_name ThrowState
extends PlayerState

var throw_timer: float = 0.0
const THROW_DURATION := 0.4


func enter() -> void:
	throw_timer = 0.0
	player.sprite.play("attack1")  # 投げ専用アニメが無い場合
	player.velocity = Vector2.ZERO
	_execute_throw()


func physics_update(delta: float) -> void:
	throw_timer += delta
	if throw_timer >= THROW_DURATION:
		state_machine.transition_to("idle")


func _execute_throw() -> void:
	# grab_state から grabbed_enemy を引き継ぐ
	var grab: GrabState = state_machine.states.get("grab") as GrabState
	if grab and grab.grabbed_enemy and grab.grabbed_enemy.has_method("be_thrown"):
		var direction := InputManager.get_movement_vector(player.player_index)
		if direction == Vector2.ZERO:
			direction = Vector2(player.get_facing_direction(), 0)
		var power := 20
		if player.character_data:
			power = player.character_data.grab_power
		grab.grabbed_enemy.be_thrown(direction, power)
		grab.grabbed_enemy = null
