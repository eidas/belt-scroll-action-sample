class_name HitEffect
extends Node2D

## ヒットスパークエフェクト（プール管理用）

@onready var sprite: AnimatedSprite2D = $Sprite
var _active: bool = false


func _ready() -> void:
	visible = false
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)


func play_at(pos: Vector2) -> void:
	global_position = pos
	visible = true
	_active = true
	if sprite:
		sprite.play("hit_spark")


func _on_animation_finished() -> void:
	visible = false
	_active = false


func is_active() -> bool:
	return _active
