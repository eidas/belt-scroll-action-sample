class_name AttackState
extends PlayerState

var current_combo: int = 0
var combo_window_open: bool = false
var next_combo_requested: bool = false
var attack_timer: float = 0.0

const COMBO_ANIMATIONS := ["attack1", "attack2", "attack3", "attack4"]
const ATTACK_DURATION := 0.35  # 各段の持続時間（秒）
const COMBO_WINDOW_START := 0.2  # コンボ受付開始時間
const HITBOX_START := 0.05  # Hitbox有効化タイミング
const HITBOX_END := 0.2  # Hitbox無効化タイミング


func enter() -> void:
	current_combo = 0
	next_combo_requested = false
	combo_window_open = false
	attack_timer = 0.0
	_start_attack()


func exit() -> void:
	player.hitbox_deactivate()
	current_combo = 0


func physics_update(delta: float) -> void:
	attack_timer += delta

	# Hitbox有効化区間
	if attack_timer >= HITBOX_START and attack_timer < HITBOX_END:
		player.hitbox_activate()
	elif attack_timer >= HITBOX_END:
		player.hitbox_deactivate()

	# コンボ受付ウィンドウ
	if attack_timer >= COMBO_WINDOW_START:
		combo_window_open = true

	# 攻撃入力チェック
	if combo_window_open and InputManager.is_action_just_pressed(player.player_index, "attack"):
		next_combo_requested = true

	# 攻撃アニメーション完了
	if attack_timer >= ATTACK_DURATION:
		if next_combo_requested and current_combo < _max_combo() - 1:
			current_combo += 1
			next_combo_requested = false
			combo_window_open = false
			attack_timer = 0.0
			_start_attack()
		else:
			state_machine.transition_to("idle")


func _start_attack() -> void:
	var anim_name: String = COMBO_ANIMATIONS[current_combo]
	if player.sprite.sprite_frames and player.sprite.sprite_frames.has_animation(anim_name):
		player.sprite.play(anim_name)
	else:
		player.sprite.play("attack1")
	player.velocity = Vector2.ZERO


func _max_combo() -> int:
	if player.character_data:
		return player.character_data.combo_count
	return 3
