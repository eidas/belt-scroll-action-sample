class_name EnemySpawner
extends Node2D

## 敵の出現管理。ウェーブ制に対応

signal all_enemies_defeated

@export var waves: Array[SpawnWave] = []
@export var player_count_multiplier: float = 1.5  # 2P時の敵数倍率

var _current_wave: int = 0
var _active_enemies: Array[Node] = []
var _spawning: bool = false


func start_spawning() -> void:
	_current_wave = 0
	_spawning = true
	_spawn_wave()


func _spawn_wave() -> void:
	if _current_wave >= waves.size():
		# 全ウェーブ完了＋敵全滅で終了
		if _active_enemies.is_empty():
			all_enemies_defeated.emit()
		return

	var wave := waves[_current_wave]
	for spawn_data in wave.spawns:
		var count := spawn_data.count
		# 2Pプレイ時の倍率
		if GameManager.player_count >= 2:
			count = ceili(count * player_count_multiplier)

		for i in count:
			_spawn_enemy(spawn_data)


func _spawn_enemy(data: SpawnData) -> void:
	if data.enemy_scene == null:
		return

	var enemy := data.enemy_scene.instantiate() as Node2D
	if enemy == null:
		return

	var offset := Vector2(randf_range(-20, 20), randf_range(-5, 5))
	enemy.global_position = global_position + data.spawn_offset + offset
	get_parent().add_child(enemy)
	_active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_removed.bind(enemy))


func _on_enemy_removed(enemy: Node) -> void:
	_active_enemies.erase(enemy)

	# 現ウェーブの敵が全滅したら次ウェーブ
	if _spawning and _active_enemies.is_empty():
		_current_wave += 1
		if _current_wave < waves.size():
			# 少し遅延して次ウェーブ
			var tween := create_tween()
			tween.tween_callback(_spawn_wave).set_delay(0.5)
		else:
			all_enemies_defeated.emit()
			_spawning = false
