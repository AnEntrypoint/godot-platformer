extends Node

var lives: int = 3
var coins: int = 0
var level: int = 1

const LEVELS := [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]

signal lives_changed(value: int)
signal coins_changed(value: int)
signal level_changed(value: int)
signal game_over


func _ready() -> void:
	print("[GameManager] initialized lives=%d coins=%d level=%d" % [lives, coins, level])


func add_coin(value: int = 1) -> void:
	coins += value
	coins_changed.emit(coins)


func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		lives = 3
		coins = 0
		level = 1
		load_level(0)


func next_level() -> void:
	level += 1
	level_changed.emit(level)
	var idx := level - 1
	if idx >= LEVELS.size():
		print("[GameManager] All levels complete! Restarting.")
		lives = 3
		coins = 0
		level = 1
		load_level(0)
	else:
		load_level(idx)


func load_level(idx: int) -> void:
	var path := LEVELS[clamp(idx, 0, LEVELS.size() - 1)]
	get_tree().change_scene_to_file(path)


func restart_level() -> void:
	load_level(level - 1)
