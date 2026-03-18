class_name EnemyAI
extends CharacterBody2D

@export var max_hp: int = 40
@export var attack_power: int = 8
@export var move_speed: float = 60.0
@export var attack_range: float = 30.0
@export var detection_range: float = 200.0
@export var attack_cooldown: float = 1.5
@export var score_type: String = "thug"  # ScoreManager の ENEMY_SCORES キー
@export var is_super_armor: bool = false  # 常時スーパーアーマー
@export var grab_immune: bool = false  # 掴み不可
@export var super_armor_threshold: int = 0  # この累積ダメージでのけぞり

var hp: int = 40
var facing_right: bool = false
var target: Node2D = null
var altitude: float = 0.0
var velocity_z: float = 0.0
var _cooldown_timer: float = 0.0
var _accumulated_damage: int = 0  # スーパーアーマー用累積ダメージ

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var state_machine: Node = $StateMachine


func _ready() -> void:
	hp = max_hp
	hitbox_deactivate()
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	z_index = int(global_position.y)
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)

	# ターゲット更新
	_update_target()

# -------- ターゲッティング --------

func _update_target() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		target = null
		return

	var closest: Node2D = null
	var min_dist := INF
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist := global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = p
	target = closest


func get_distance_to_target() -> float:
	if target:
		return global_position.distance_to(target.global_position)
	return INF


func get_direction_to_target() -> Vector2:
	if target:
		return (target.global_position - global_position).normalized()
	return Vector2.ZERO


func is_in_attack_range() -> bool:
	return get_distance_to_target() <= attack_range


func can_attack() -> bool:
	return _cooldown_timer <= 0.0 and is_in_attack_range()


func start_cooldown() -> void:
	_cooldown_timer = attack_cooldown

# -------- ダメージ処理 --------

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	hp = max(hp, 0)

	if is_super_armor and super_armor_threshold > 0:
		_accumulated_damage += amount
		if _accumulated_damage >= super_armor_threshold:
			_accumulated_damage = 0
			_on_staggered(knockback)
	elif not is_super_armor:
		_on_staggered(knockback)

	if is_dead():
		_on_defeated()


func _on_staggered(knockback: Vector2) -> void:
	if knockback != Vector2.ZERO:
		velocity = knockback
		move_and_slide()
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("hit")


func _on_defeated() -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("dead")


func is_dead() -> bool:
	return hp <= 0


func is_grab_immune() -> bool:
	return grab_immune

# -------- 掴み・投げ --------

func be_grabbed(_grabber: Node) -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("grabbed")


func release_from_grab() -> void:
	if state_machine and state_machine.has_method("transition_to"):
		state_machine.transition_to("idle")


func be_thrown(direction: Vector2, power: int) -> void:
	take_damage(power)
	velocity = direction * 300.0
	altitude = 20.0
	velocity_z = 150.0
	# 投げ状態の処理は Phase 5 で拡充

# -------- Hitbox --------

func hitbox_activate() -> void:
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = false


func hitbox_deactivate() -> void:
	for child in hitbox.get_children():
		if child is CollisionShape2D:
			child.disabled = true


func update_facing() -> void:
	if target:
		facing_right = target.global_position.x > global_position.x
	if sprite:
		sprite.flip_h = not facing_right
