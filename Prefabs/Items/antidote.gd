extends Node2D

@export var CURE_VALUE: int = 50
#@export var PLAYER_PATH: NodePath
#@onready var player = get_node(PLAYER_PATH)
@onready var area: Area2D = $Area2D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	body.SANITY += CURE_VALUE
	queue_free()
