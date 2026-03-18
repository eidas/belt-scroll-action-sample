class_name CombatSystem
extends Node

## 戦闘全体のダメージ計算・コンボ管理・ヒットストップを担当する

const HITSTOP_FRAMES := 3  # ヒットストップのフレーム数
const KNOCKDOWN_THRESHOLD := 30  # この値以上のダメージでノックダウン

# コンボ追跡
var _combo_counts: Dictionary = {}  # entity -> combo_count
var _combo_timers: Dictionary = {}  # entity -> reset_timer
const COMBO_RESET_TIME := 1.0


static func apply_damage(target: Node, hitbox: Hitbox) -> void:
	if target.has_method("take_damage"):
		var knockback := hitbox.knockback_force
		if hitbox.owner_entity and hitbox.owner_entity is Node2D and target is Node2D:
			var dir := (target.global_position - hitbox.owner_entity.global_position).normalized()
			knockback = dir * hitbox.knockback_force.length()
		target.take_damage(hitbox.damage, knockback)

	# ヒットストップ
	if hitbox.hit_stun_duration > 0:
		_apply_hitstop(target, hitbox.hit_stun_duration)
		if hitbox.owner_entity:
			_apply_hitstop(hitbox.owner_entity, hitbox.hit_stun_duration)


static func _apply_hitstop(entity: Node, duration: float) -> void:
	if entity.has_method("start_hitstop"):
		entity.start_hitstop(duration)
	else:
		# フォールバック: AnimatedSprite2D を一時停止
		var sprite := entity.get_node_or_null("Sprite") as AnimatedSprite2D
		if sprite:
			sprite.pause()
			var tween := entity.create_tween()
			tween.tween_callback(func():
				if is_instance_valid(sprite):
					sprite.play()
			).set_delay(duration)
