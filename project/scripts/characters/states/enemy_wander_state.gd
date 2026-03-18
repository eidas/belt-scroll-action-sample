class_name EnemyWanderState
extends EnemyState

var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
const WANDER_DURATION := 1.5
const WANDER_SPEED_RATIO := 0.4


func enter() -> void:
	wander_timer = 0.0
	wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	if enemy.sprite:
		enemy.sprite.play("walk") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("walk") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	wander_timer += delta

	# プレイヤー検知
	if enemy.target and enemy.get_distance_to_target() <= enemy.detection_range:
		state_machine.transition_to("chase")
		return

	if wander_timer >= WANDER_DURATION:
		state_machine.transition_to("idle")
		return

	enemy.velocity = wander_direction * enemy.move_speed * WANDER_SPEED_RATIO
	enemy.move_and_slide()
