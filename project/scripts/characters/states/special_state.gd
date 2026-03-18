class_name SpecialState
extends PlayerState

var timer: float = 0.0
const SPECIAL_DURATION := 0.6
const HITBOX_START := 0.1
const HITBOX_END := 0.4


func enter() -> void:
	timer = 0.0

	# HP消費チェック
	var cost := 15
	if player.character_data:
		cost = player.character_data.special_hp_cost

	if player.hp <= cost:
		# HP不足で不発
		state_machine.transition_to("idle")
		return

	player.hp -= cost
	player.is_invincible = true
	player.sprite.play("attack1")  # 必殺技専用アニメが無い場合
	player.velocity = Vector2.ZERO


func exit() -> void:
	player.hitbox_deactivate()
	player.is_invincible = false


func physics_update(delta: float) -> void:
	timer += delta

	if timer >= HITBOX_START and timer < HITBOX_END:
		player.hitbox_activate()
	elif timer >= HITBOX_END:
		player.hitbox_deactivate()

	if timer >= SPECIAL_DURATION:
		state_machine.transition_to("idle")
