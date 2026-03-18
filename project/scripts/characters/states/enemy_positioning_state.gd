class_name EnemyPositioningState
extends EnemyState

## 攻撃位置取り: プレイヤーを包囲するように移動し、攻撃枠が空いたら攻撃

var _attack_manager: EnemyAttackManager
var _position_timer: float = 0.0
const REPOSITION_INTERVAL := 0.5


func enter() -> void:
	_position_timer = 0.0
	_attack_manager = _find_attack_manager()
	if enemy.sprite:
		enemy.sprite.play("walk") if enemy.sprite.sprite_frames and enemy.sprite.sprite_frames.has_animation("walk") else enemy.sprite.play("idle")


func physics_update(delta: float) -> void:
	if not enemy.target:
		state_machine.transition_to("idle")
		return

	# 攻撃枠の確認
	if enemy.can_attack():
		if _attack_manager == null or _attack_manager.request_attack_slot(enemy):
			state_machine.transition_to("attack")
			return

	# 包囲移動: ターゲットの周囲をゆっくり移動
	_position_timer += delta
	if _position_timer >= REPOSITION_INTERVAL:
		_position_timer = 0.0

	var to_target := enemy.get_direction_to_target()
	var dist := enemy.get_distance_to_target()

	# 適切な距離を維持
	var desired_dist := enemy.attack_range * 0.8
	var move_dir := Vector2.ZERO

	if dist > desired_dist + 10:
		move_dir = to_target
	elif dist < desired_dist - 10:
		move_dir = -to_target

	# 横方向のずらし（包囲行動）
	var lateral := Vector2(-to_target.y, to_target.x)
	move_dir += lateral * 0.3

	if move_dir != Vector2.ZERO:
		enemy.velocity = move_dir.normalized() * enemy.move_speed * 0.5
		enemy.move_and_slide()

	enemy.update_facing()


func _find_attack_manager() -> EnemyAttackManager:
	var managers := enemy.get_tree().get_nodes_in_group("attack_manager")
	if managers.size() > 0:
		return managers[0] as EnemyAttackManager
	# ステージ上のノードから探す
	var parent := enemy.get_parent()
	for child in parent.get_children():
		if child is EnemyAttackManager:
			return child
	return null
