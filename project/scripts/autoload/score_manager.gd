extends Node

signal score_changed(player_index: int, new_score: int)
signal highscore_changed(new_highscore: int)

# 敵種別スコア
const ENEMY_SCORES := {
	"thug": 100,
	"knifeman": 200,
	"punks": 300,
	"firebomber": 400,
	"bigman": 500,
	"bouncer": 5000,
	"kunoichi": 10000,
	"boss_x": 20000,
}

const COMBO_BONUS_MULTIPLIER := 50
const NO_DAMAGE_BONUS := 10000
const TIME_BONUS_MULTIPLIER := 10
const EXTRA_LIFE_THRESHOLD := 50000

var scores: Array[int] = [0, 0]
var highscore: int = 0
var combo_counts: Array[int] = [0, 0]
var _next_extra_life_at: Array[int] = [EXTRA_LIFE_THRESHOLD, EXTRA_LIFE_THRESHOLD]


func _ready() -> void:
	_load_highscore()


func add_score(player_index: int, points: int) -> void:
	scores[player_index] += points
	score_changed.emit(player_index, scores[player_index])

	# 1UPチェック
	while scores[player_index] >= _next_extra_life_at[player_index]:
		_next_extra_life_at[player_index] += EXTRA_LIFE_THRESHOLD
		# 残機追加は GameManager 経由で行う（後で接続）

	if scores[player_index] > highscore:
		highscore = scores[player_index]
		highscore_changed.emit(highscore)


func add_enemy_score(player_index: int, enemy_type: String) -> void:
	var points: int = ENEMY_SCORES.get(enemy_type, 100)
	add_score(player_index, points)


func add_combo_bonus(player_index: int, combo_count: int) -> void:
	var bonus := combo_count * COMBO_BONUS_MULTIPLIER
	add_score(player_index, bonus)


func calculate_stage_clear_bonus(player_index: int, remaining_time: int, took_damage: bool) -> int:
	var bonus := remaining_time * TIME_BONUS_MULTIPLIER
	if not took_damage:
		bonus += NO_DAMAGE_BONUS
	add_score(player_index, bonus)
	return bonus


func reset() -> void:
	scores = [0, 0]
	combo_counts = [0, 0]
	_next_extra_life_at = [EXTRA_LIFE_THRESHOLD, EXTRA_LIFE_THRESHOLD]


func _load_highscore() -> void:
	var config := ConfigFile.new()
	if config.load("user://highscore.cfg") == OK:
		highscore = config.get_value("score", "highscore", 0)


func save_highscore() -> void:
	var config := ConfigFile.new()
	config.set_value("score", "highscore", highscore)
	config.save("user://highscore.cfg")
