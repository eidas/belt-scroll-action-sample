class_name StageManager
extends Node

signal stage_cleared
signal time_up

@export var stage_time: int = 90  # 制限時間（秒）

var remaining_time: int = 90
var took_damage: bool = false
var enemies_defeated: int = 0
var max_combo: int = 0
var _timer_active: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	remaining_time = stage_time


func _process(delta: float) -> void:
	if not _timer_active:
		return

	_elapsed += delta
	if _elapsed >= 1.0:
		_elapsed -= 1.0
		remaining_time -= 1
		if remaining_time <= 0:
			remaining_time = 0
			_timer_active = false
			time_up.emit()


func start_timer() -> void:
	remaining_time = stage_time
	_elapsed = 0.0
	_timer_active = true
	took_damage = false
	enemies_defeated = 0
	max_combo = 0


func stop_timer() -> void:
	_timer_active = false


func on_enemy_defeated() -> void:
	enemies_defeated += 1


func on_player_damaged() -> void:
	took_damage = true


func on_combo_update(combo_count: int) -> void:
	max_combo = max(max_combo, combo_count)


func clear_stage() -> void:
	stop_timer()
	# スコア計算
	for i in GameManager.player_count:
		ScoreManager.calculate_stage_clear_bonus(i, remaining_time, took_damage)
	stage_cleared.emit()
