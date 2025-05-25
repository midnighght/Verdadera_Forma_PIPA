extends Node2D
# Get player node
@export var PLAYER_PATH: NodePath
@onready var player = get_node(PLAYER_PATH)

@onready var health_bar = $TextureProgressBar
@onready var max_health: int = player.MAX_SANITY

# Set start values
func _ready():
	health_bar.max_value = max_health
	health_bar.value = max_health

# if player exists, set progress bar value to player health (SANITY)
func _process(_delta):
	if player:
		health_bar.value = clamp(player.SANITY, 0, max_health)
