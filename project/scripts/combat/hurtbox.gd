class_name Hurtbox
extends Area2D

signal on_hit(hitbox: Hitbox)

var invincible: bool = false
var _invincible_timer: float = 0.0

const DEFAULT_INVINCIBLE_DURATION := 0.2  # 被弾後の短時間無敵


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if invincible and _invincible_timer > 0.0:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			invincible = false


func _on_area_entered(area: Area2D) -> void:
	if invincible:
		return
	if area is Hitbox:
		var hitbox := area as Hitbox
		var owner_node := get_parent()
		if owner_node is Node2D and hitbox.can_hit(owner_node):
			on_hit.emit(hitbox)
			start_invincibility(DEFAULT_INVINCIBLE_DURATION)


func start_invincibility(duration: float) -> void:
	invincible = true
	_invincible_timer = duration
