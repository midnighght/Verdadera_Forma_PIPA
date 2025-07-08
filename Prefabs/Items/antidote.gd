extends Node2D

@export var CURE_VALUE: int = 150
@export var BAT_PATH: NodePath
@onready var bat = get_node(BAT_PATH).get_node("Bat")
@onready var area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var is_active: bool = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	is_active = false
	area.monitoring = false
	sprite.modulate.a = 0.4

	if bat and bat.has_signal("death"):
		bat.connect("death", _on_bat_death)

func _on_body_entered(body):
	if is_active:
		body.SANITY += CURE_VALUE
		queue_free()
		
func _on_bat_death():
	is_active = true
	area.monitoring = true
	sprite.modulate.a = 1.0
