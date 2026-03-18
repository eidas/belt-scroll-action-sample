class_name SpawnTrigger
extends Area2D

## プレイヤーが到達するとカメラロック→敵スポーン→全滅で解除

signal encounter_started
signal encounter_cleared

@export var enemy_spawner_path: NodePath
@export var auto_lock_camera: bool = true

var triggered: bool = false
var _spawner: EnemySpawner
var _camera: ScrollCamera


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if enemy_spawner_path:
		_spawner = get_node_or_null(enemy_spawner_path) as EnemySpawner


func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if not body.is_in_group("players"):
		return

	triggered = true
	encounter_started.emit()

	# カメラロック
	if auto_lock_camera:
		_camera = _find_camera()
		if _camera:
			_camera.lock_scroll()

	# 敵スポーン
	if _spawner:
		_spawner.start_spawning()
		_spawner.all_enemies_defeated.connect(_on_all_defeated, CONNECT_ONE_SHOT)
	else:
		# スポーナーがなければ即解除
		_on_all_defeated()


func _on_all_defeated() -> void:
	if _camera:
		_camera.unlock_scroll()
	encounter_cleared.emit()


func _find_camera() -> ScrollCamera:
	var cameras := get_tree().get_nodes_in_group("camera")
	for c in cameras:
		if c is ScrollCamera:
			return c
	# フォールバック: シーン内の Camera2D を探す
	var viewport := get_viewport()
	if viewport and viewport.get_camera_2d() is ScrollCamera:
		return viewport.get_camera_2d() as ScrollCamera
	return null
