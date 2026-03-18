class_name HitState
extends PlayerState

var stun_timer: float = 0.0
const HITSTUN_DURATION := 0.3


func enter() -> void:
	stun_timer = 0.0
	player.sprite.play("hit") if player.sprite.sprite_frames and player.sprite.sprite_frames.has_animation("hit") else player.sprite.play("idle")
	player.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	stun_timer += delta

	# のけぞり中の移動減衰
	player.velocity = player.velocity.lerp(Vector2.ZERO, 0.1)
	player.move_and_slide()

	if stun_timer >= HITSTUN_DURATION:
		if player.is_dead():
			state_machine.transition_to("knockdown")
		else:
			state_machine.transition_to("idle")
