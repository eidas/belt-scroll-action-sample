class_name JumpAttackState
extends PlayerState

var _attack_started: bool = false
const LANDING_RECOVERY := 0.2  # 着地硬直時間
var _recovery_timer: float = 0.0
var _landed: bool = false


func enter() -> void:
	player.sprite.play("jump_attack") if player.sprite.sprite_frames and player.sprite.sprite_frames.has_animation("jump_attack") else player.sprite.play("attack1")
	player.hitbox_activate()
	_attack_started = true
	_landed = false
	_recovery_timer = 0.0


func exit() -> void:
	player.hitbox_deactivate()


func physics_update(delta: float) -> void:
	if _landed:
		_recovery_timer += delta
		if _recovery_timer >= LANDING_RECOVERY:
			state_machine.transition_to("idle")
		return

	# 空中移動
	var direction := InputManager.get_movement_vector(player.player_index)
	var speed := 120.0
	if player.character_data:
		speed = player.character_data.move_speed
	player.apply_movement(direction, speed, delta)

	# 高さ更新
	var landed := player.update_altitude(delta)
	if landed:
		_landed = true
		player.hitbox_deactivate()
		player.sprite.play("idle")
		player.velocity = Vector2.ZERO
