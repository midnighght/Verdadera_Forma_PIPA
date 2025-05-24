extends Node2D

@export var PLAYER_PATH: NodePath

@onready var player = get_node(PLAYER_PATH)
@onready var sanity_max: int = player.MAX_SANITY

func _ready():
	$SanityProgressBar.max_value = sanity_max
	$SanityProgressBar.value = sanity_max

func _process(_delta):
	if player:
		$SanityProgressBar.value = clamp(player.SANITY, 0, sanity_max)
