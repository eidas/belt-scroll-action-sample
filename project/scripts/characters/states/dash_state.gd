class_name DashState
extends PlayerState

var dash_timer: float = 0.0
var dash_direction: float = 0.0
const DASH_DURATION := 0.5


func enter() -> void:
	dash_timer = 0.0
	dash_direction = player.get_facing_direction()
	player.sprite.play("walk")  # ダッシュ専用アニメが無い場合はwalk


func physics_update(delta: float) -> void:
	dash_timer += delta

	# ダッシュ攻撃
	if InputManager.is_action_just_pressed(player.player_index, "attack"):
		state_machine.transition_to("dashattack")
		return

	# ダッシュ終了
	if dash_timer >= DASH_DURATION:
		state_machine.transition_to("idle")
		return

	var speed := 200.0
	if player.character_data:
		speed = player.character_data.dash_speed
	var move := Vector2(dash_direction * speed, 0)
	player.velocity = move
	player.move_and_slide()
