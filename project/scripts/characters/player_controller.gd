class_name PlayerController
extends CharacterBody2D

@export var character_data: CharacterData
@export var player_index: int = 0

var hp: int = 100
var lives: int = 3
var facing_right: bool = true
var altitude: float = 0.0  # ジャンプ用の擬似高さ
var velocity_z: float = 0.0  # ジャンプ用の垂直速度
var is_invincible: bool = false
var held_weapon = null  # 武器所持（Phase 7 で型を追加）

# ノード参照
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var state_machine: Node = $StateMachine

const DEPTH_MOVE_RATIO := 0.6  # 奥行き移動速度比率
const GRAVITY := 600.0
const GROUND_Y_MIN := 140.0  # 奥行き移動可能範囲（上限）
const GROUND_Y_MAX := 210.0  # 奥行き移動可能範囲（下限）


func _ready() -> void:
	if character_data:
		hp = character_data.max_hp
	_update_facing()
	hitbox_deactivate()


func _physics_process(_delta: float) -> void:
	# 奥行きソート: Y座標が大きいほど手前に描画
	z_index = int(global_position.y)


func apply_movement(direction: Vector2, speed: float, delta: float) -> void:
	var move_velocity := Vector2.ZERO
	move_velocity.x = direction.x * speed
	move_velocity.y = direction.y * speed * DEPTH_MOVE_RATIO

	velocity = move_velocity
	move_and_slide()

	# 奥行き移動範囲を制限
	global_position.y = clampf(global_position.y, GROUND_Y_MIN, GROUND_Y_MAX)

	# 向き切替
	if direction.x > 0.1:
		facing_right = true
		_update_facing()
	elif direction.x < -0.1:
		facing_right = false
		_update_facing()


func _update_facing() -> void:
	if sprite:
		sprite.flip_h = not facing_right


func update_altitude(delta: float) -> bool:
	velocity_z -= GRAVITY * delta
	altitude += velocity_z * delta

	if altitude <= 0.0:
		altitude = 0.0
		velocity_z = 0.0
		sprite.offset.y = 0.0
		return true  # 着地した

	sprite.offset.y = -altitude
	return false  # まだ空中


func jump(force: float) -> void:
	altitude = 0.0
	velocity_z = force


func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return
	hp -= amount
	hp = max(hp, 0)
	if knockback != Vector2.ZERO:
		velocity = knockback
		move_and_slide()


func heal(amount: int) -> void:
	if character_data:
		hp = min(hp + amount, character_data.max_hp)


func is_dead() -> bool:
	return hp <= 0


func hitbox_activate() -> void:
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = false


func hitbox_deactivate() -> void:
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = true


func get_facing_direction() -> float:
	return 1.0 if facing_right else -1.0
