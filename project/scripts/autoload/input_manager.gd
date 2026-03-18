extends Node

const ACTION_PREFIX := ["p1_", "p2_"]
const DIRECTIONS := ["up", "down", "left", "right"]
const BUTTONS := ["attack", "jump", "special"]

# ダッシュ検知用: 方向キーの最終入力時刻
var _last_direction_time: Array[Dictionary] = [{}, {}]
const DASH_INPUT_WINDOW := 0.2  # 200ms


func get_action_name(player_index: int, action: String) -> String:
	return ACTION_PREFIX[player_index] + action


func get_movement_vector(player_index: int) -> Vector2:
	var prefix := ACTION_PREFIX[player_index]
	var x := Input.get_axis(prefix + "left", prefix + "right")
	var y := Input.get_axis(prefix + "up", prefix + "down")
	return Vector2(x, y).normalized() if Vector2(x, y).length() > 0.1 else Vector2.ZERO


func is_action_just_pressed(player_index: int, action: String) -> bool:
	return Input.is_action_just_pressed(get_action_name(player_index, action))


func is_action_pressed(player_index: int, action: String) -> bool:
	return Input.is_action_pressed(get_action_name(player_index, action))


func is_action_just_released(player_index: int, action: String) -> bool:
	return Input.is_action_just_released(get_action_name(player_index, action))


func check_dash_input(player_index: int, direction: String) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	var action := get_action_name(player_index, direction)

	if Input.is_action_just_pressed(action):
		var last_time: float = _last_direction_time[player_index].get(direction, 0.0)
		_last_direction_time[player_index][direction] = now
		if now - last_time <= DASH_INPUT_WINDOW:
			return true
	return false


func is_special_input(player_index: int) -> bool:
	# 専用ボタン or 攻撃+ジャンプ同時押し
	if is_action_just_pressed(player_index, "special"):
		return true
	if is_action_just_pressed(player_index, "attack") and is_action_pressed(player_index, "jump"):
		return true
	if is_action_just_pressed(player_index, "jump") and is_action_pressed(player_index, "attack"):
		return true
	return false
