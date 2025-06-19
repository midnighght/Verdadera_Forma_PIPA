extends StaticBody2D
@export var PLAYER_PATH: NodePath
@export var OFFSET: float = 4096.0

@onready var player = get_node(PLAYER_PATH).get_node("Urlu")
var max_x: float = 0.0

func _process(_delta):
	var target_x = player.global_position.x - OFFSET
	if target_x > max_x:
		max_x = target_x
	position.x = max_x
