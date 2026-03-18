class_name Hitbox
extends Area2D

@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2(100, 0)
@export var hit_stun_duration: float = 0.05  # 2-4フレーム（約33-66ms）

var owner_entity: Node = null

const DEPTH_TOLERANCE := 8.0  # 奥行き許容幅 ±8px


func _ready() -> void:
	owner_entity = get_parent().get_parent() if get_parent() else null


func activate() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false
	monitoring = true


func deactivate() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
	monitoring = false


func can_hit(target: Node2D) -> bool:
	if target == owner_entity:
		return false
	# 奥行き判定
	if owner_entity and owner_entity is Node2D:
		var depth_diff := absf(owner_entity.global_position.y - target.global_position.y)
		if depth_diff > DEPTH_TOLERANCE:
			return false
	return true
