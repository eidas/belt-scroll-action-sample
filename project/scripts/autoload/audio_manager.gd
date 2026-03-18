extends Node

const SE_POOL_SIZE := 8

var _bgm_player: AudioStreamPlayer
var _se_players: Array[AudioStreamPlayer] = []
var _se_index: int = 0

var bgm_volume: float = 1.0:
	set(value):
		bgm_volume = value
		if _bgm_player:
			_bgm_player.volume_db = linear_to_db(value)

var se_volume: float = 1.0


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	for i in SE_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_se_players.append(player)


func play_bgm(stream: AudioStream, from_position: float = 0.0) -> void:
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(bgm_volume)
	_bgm_player.play(from_position)


func stop_bgm() -> void:
	_bgm_player.stop()


func play_se(stream: AudioStream) -> void:
	if stream == null:
		return
	var player := _se_players[_se_index]
	player.stream = stream
	player.volume_db = linear_to_db(se_volume)
	player.play()
	_se_index = (_se_index + 1) % SE_POOL_SIZE
