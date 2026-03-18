class_name DashAttackState
extends PlayerState

var attack_timer: float = 0.0
const ATTACK_DURATION := 0.4
const HITBOX_START := 0.05
const HITBOX_END := 0.25
var _dash_direction: float = 0.0


func enter() -> void:
	attack_timer = 0.0
	_dash_direction = player.get_facing_direction()
	player.sprite.play("attack1")  # ダッシュ攻撃専用アニメが無い場合
	player.velocity = Vector2.ZERO


func exit() -> void:
	player.hitbox_deactivate()


func physics_update(delta: float) -> void:
	attack_timer += delta

	# 突進しながら攻撃
	var speed := 150.0
	if player.character_data:
		speed = player.character_data.dash_speed * 0.6
	player.velocity = Vector2(_dash_direction * speed, 0)
	player.move_and_slide()

	# Hitbox制御
	if attack_timer >= HITBOX_START and attack_timer < HITBOX_END:
		player.hitbox_activate()
	elif attack_timer >= HITBOX_END:
		player.hitbox_deactivate()

	if attack_timer >= ATTACK_DURATION:
		state_machine.transition_to("idle")
