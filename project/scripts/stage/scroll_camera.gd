class_name ScrollCamera
extends Camera2D

@export var scroll_speed_smoothing: float = 5.0
@export var y_smoothing: float = 2.0
@export var camera_y_min: float = 80.0
@export var camera_y_max: float = 144.0

var scroll_locked: bool = false
var scroll_lock_x: float = 0.0
var _left_boundary: float = 0.0  # 逆スクロール不可の左端
var targets: Array[Node2D] = []

# 画面揺れ
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	if targets.is_empty():
		return

	var target_pos := _get_target_center()

	# X軸: 追従（逆スクロール不可）
	var target_x := target_pos.x
	if scroll_locked:
		target_x = minf(target_x, scroll_lock_x)

	# 左端制限の更新（前方にしか進めない）
	_left_boundary = maxf(_left_boundary, global_position.x - 20)
	target_x = maxf(target_x, _left_boundary)

	# Y軸: 緩やかに追従
	var target_y := clampf(target_pos.y, camera_y_min, camera_y_max)

	global_position.x = lerpf(global_position.x, target_x, scroll_speed_smoothing * delta)
	global_position.y = lerpf(global_position.y, target_y, y_smoothing * delta)

	# 画面揺れ
	if _shake_timer > 0:
		_shake_timer -= delta
		offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		offset = Vector2.ZERO


func set_targets(new_targets: Array[Node2D]) -> void:
	targets = new_targets


func lock_scroll() -> void:
	scroll_locked = true
	scroll_lock_x = global_position.x + get_viewport_rect().size.x * 0.5


func unlock_scroll() -> void:
	scroll_locked = false


func shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration


func _get_target_center() -> Vector2:
	var valid_targets: Array[Node2D] = []
	for t in targets:
		if is_instance_valid(t):
			valid_targets.append(t)

	if valid_targets.is_empty():
		return global_position

	if valid_targets.size() == 1:
		return valid_targets[0].global_position

	# 2人の中間点
	var center := Vector2.ZERO
	for t in valid_targets:
		center += t.global_position
	return center / valid_targets.size()
