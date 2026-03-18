extends Node

enum GameState {
	TITLE,
	SELECT,
	PLAYING,
	PAUSED,
	GAMEOVER,
	ENDING,
}

var current_state: GameState = GameState.TITLE
var player_count: int = 1
var current_stage: int = 1
var continue_count: int = 3

var _previous_state: GameState = GameState.TITLE


func change_state(new_state: GameState) -> void:
	_previous_state = current_state
	current_state = new_state


func start_game(num_players: int) -> void:
	player_count = num_players
	current_stage = 1
	continue_count = 3
	change_state(GameState.PLAYING)


func use_continue() -> bool:
	if continue_count > 0:
		continue_count -= 1
		return true
	return false


func reset() -> void:
	current_state = GameState.TITLE
	player_count = 1
	current_stage = 1
	continue_count = 3
