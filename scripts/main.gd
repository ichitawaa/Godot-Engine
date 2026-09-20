extends Node2D
@onready var score_label: Label = $HUD/ScorePanel/ScoreLabel
@onready var fade: ColorRect = $HUD/Fade

var level: int = 1
var score: int = 0
var current_level_root: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Setup the level
	fade.modulate.a = 1.0	
	current_level_root = get_node("LevelRoot")
	await _load_level(level, true, false) 

# --------------------
# LEVEL MANAGEMENT
# --------------------

func _load_level(level_number: int, first_load: bool = false, reset_score: bool = false) -> void:
	# Fade out
	if not first_load:  
		await fade_effect(1.0)  

	if reset_score:
		score = 0 
		score_label.text = "SCORE : 0"

	if current_level_root:
		current_level_root.queue_free()
		
	# Change Level
	var level_path = "res://scenes/levels/level%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	_setup_level(current_level_root)

	# Fade in
	await fade_effect(0.0)

func _setup_level(level_root: Node) -> void:
	# Connect Exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)
	
	# connect emerald/collectibles
	var emerald = level_root.get_node_or_null("Emerald")
	if emerald:
		for item in emerald.get_children():
			item.collected.connect(increase_score)

	# connect enemies
	var enemies = level_root.get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			enemy.player_died.connect(_on_player_died)

# --------------------
# Signal Handlers
# --------------------
func _on_exit_body_entered(body : Node2D) -> void:
	if body.name == "Player":
		level += 1
		body.can_move = false
		await _load_level(level, false, false)


func _on_player_died(body):
	body.die()
	await _load_level(level, false, true)

# --------------------
# SCORE
# --------------------

func increase_score() -> void:
	score += 1
	score_label.text = "SCORE : %s" % score

# --------------------
# FADE EFFECT (TWEEN)
# --------------------

func fade_effect(to_alpha: float) -> void:
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", to_alpha, 1.5)
	await tween.finished
