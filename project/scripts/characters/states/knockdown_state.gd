class_name KnockdownState
extends PlayerState

var timer: float = 0.0
const DOWN_DURATION := 0.8


func enter() -> void:
	timer = 0.0
	player.sprite.play("down") if player.sprite.sprite_frames and player.sprite.sprite_frames.has_animation("down") else player.sprite.play("idle")
	player.velocity = Vector2.ZERO
	player.is_invincible = true


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	timer += delta

	player.velocity = player.velocity.lerp(Vector2.ZERO, 0.15)
	player.move_and_slide()

	if timer >= DOWN_DURATION:
		if player.is_dead():
			state_machine.transition_to("dead")
		else:
			state_machine.transition_to("getup")
