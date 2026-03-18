class_name EnemyAttackManager
extends Node

## 同時攻撃制限マネージャー
## 画面内で同時にプレイヤーを攻撃できる敵は最大2〜3体

const MAX_SIMULTANEOUS_ATTACKERS := 3

var _active_attackers: Array[Node] = []


func request_attack_slot(enemy: Node) -> bool:
	# 既に枠を持っている場合
	if enemy in _active_attackers:
		return true
	# 枠に空きがある場合
	if _active_attackers.size() < MAX_SIMULTANEOUS_ATTACKERS:
		_active_attackers.append(enemy)
		return true
	return false


func release_attack_slot(enemy: Node) -> void:
	_active_attackers.erase(enemy)


func cleanup() -> void:
	# 無効になったエンティティを除去
	_active_attackers = _active_attackers.filter(func(e): return is_instance_valid(e))
