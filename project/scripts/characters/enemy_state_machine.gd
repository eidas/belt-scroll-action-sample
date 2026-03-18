class_name EnemyStateMachine
extends Node

@export var initial_state: NodePath

var current_state: EnemyState
var states: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.enemy = get_parent() as EnemyAI

	if initial_state:
		current_state = get_node(initial_state)
	elif states.size() > 0:
		current_state = states.values()[0]

	if current_state:
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func transition_to(state_name: String) -> void:
	var new_state: EnemyState = states.get(state_name.to_lower())
	if new_state == null:
		push_warning("Enemy state not found: " + state_name)
		return
	if new_state == current_state:
		return

	current_state.exit()
	current_state = new_state
	current_state.enter()
