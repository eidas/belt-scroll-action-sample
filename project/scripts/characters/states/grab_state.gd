class_name GrabState
extends PlayerState

var grab_timer: float = 0.0
var grabbed_enemy: Node = null
const GRAB_DURATION := 2.0  # 振りほどきまでの時間
const GRAB_ATTACK_MAX := 3


func enter() -> void:
	grab_timer = 0.0
	player.velocity = Vector2.ZERO
	player.sprite.play("idle")


func exit() -> void:
	_release_enemy()


func physics_update(delta: float) -> void:
	grab_timer += delta

	# 自動解除
	if grab_timer >= GRAB_DURATION:
		state_machine.transition_to("idle")
		return

	var pi := player.player_index

	# 投げ: 方向+攻撃
	var direction := InputManager.get_movement_vector(pi)
	if direction != Vector2.ZERO and InputManager.is_action_just_pressed(pi, "attack"):
		state_machine.transition_to("throw")
		return

	# 掴み打撃: 攻撃のみ
	if InputManager.is_action_just_pressed(pi, "attack"):
		state_machine.transition_to("grabattack")
		return


func set_grabbed_enemy(enemy: Node) -> void:
	grabbed_enemy = enemy


func _release_enemy() -> void:
	if grabbed_enemy and grabbed_enemy.has_method("release_from_grab"):
		grabbed_enemy.release_from_grab()
	grabbed_enemy = null
