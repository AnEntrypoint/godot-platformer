extends CanvasLayer

@onready var lives_label: Label = $Control/LivesLabel
@onready var coins_label: Label = $Control/CoinsLabel
@onready var level_label: Label = $Control/LevelLabel


func _ready() -> void:
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.level_changed.connect(_on_level_changed)
	_refresh()


func _refresh() -> void:
	lives_label.text = "Lives: %d" % GameManager.lives
	coins_label.text = "Coins: %d" % GameManager.coins
	level_label.text = "Level: %d" % GameManager.level


func _on_lives_changed(value: int) -> void:
	lives_label.text = "Lives: %d" % value


func _on_coins_changed(value: int) -> void:
	coins_label.text = "Coins: %d" % value


func _on_level_changed(value: int) -> void:
	level_label.text = "Level: %d" % value
