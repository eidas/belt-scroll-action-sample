class_name CharacterData
extends Resource

@export var character_name: String = ""
@export var max_hp: int = 100
@export var attack_power: int = 10
@export var move_speed: float = 120.0
@export var dash_speed: float = 200.0
@export var jump_force: float = 300.0
@export var combo_count: int = 3  # 最大コンボ段数（3〜4）
@export var grab_power: int = 20
@export var special_hp_cost: int = 15
@export var special_damage: int = 25
@export var sprite_frames: SpriteFrames
