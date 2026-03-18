class_name GrabSystem
extends Node

const GRAB_RANGE := 24.0  # 掴み判定距離


static func can_grab(player: PlayerController, enemy: Node2D) -> bool:
	if not is_instance_valid(enemy):
		return false

	# 掴み不可フラグチェック
	if enemy.has_method("is_grab_immune") and enemy.is_grab_immune():
		return false

	# 距離チェック
	var dist := player.global_position.distance_to(enemy.global_position)
	if dist > GRAB_RANGE:
		return false

	# 奥行きチェック
	var depth_diff := absf(player.global_position.y - enemy.global_position.y)
	if depth_diff > Hitbox.DEPTH_TOLERANCE:
		return false

	# 正面チェック
	var dir := enemy.global_position.x - player.global_position.x
	if (dir > 0 and not player.facing_right) or (dir < 0 and player.facing_right):
		return false

	return true


static func execute_grab(player: PlayerController, enemy: Node2D) -> void:
	if enemy.has_method("be_grabbed"):
		enemy.be_grabbed(player)
