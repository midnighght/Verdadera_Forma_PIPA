extends Node2D

@export var WAGON_SCENES: Array[PackedScene]
@export var FIRST_WAGON_SCENE: PackedScene

var wagons = []
var last_spawn_x = 0
@export var SPAWN_TRESHOLD = 1280
@export var DESPAWN_TRESHOLD = 4096 + 1920/2
@export var PLAYER_PATH: NodePath
@onready var player = get_node(PLAYER_PATH).get_node("Urlu")

func _ready():
	var first_wagon = FIRST_WAGON_SCENE.instantiate()
	get_parent().add_child.call_deferred(first_wagon)
	first_wagon.global_position = Vector2.ZERO
	wagons.append(first_wagon)
	last_spawn_x = first_wagon.get_node("Marker2D").position.x if first_wagon.has_node("Marker2D") else 2560

func _process(_delta):
	var player_x = player.global_position.x

	# Spawn ahead if needed
	if player_x + SPAWN_TRESHOLD > last_spawn_x:
		spawn_wagon()
	
	# Despawn wagons far behind
	for wagon in wagons:
		if !is_instance_valid(wagon):
			continue
		#if !wagon.has_node("Marker2D"):
			#continue
		var marker_x = wagon.global_position.x + wagon.get_node("Marker2D").position.x
		if marker_x < player_x - DESPAWN_TRESHOLD:
			wagon.queue_free()

	# Clean up referencesd
	wagons = wagons.filter(func(w): return is_instance_valid(w) and w.is_inside_tree())
	
func spawn_wagon():
	var scene = WAGON_SCENES.pick_random()
	var wagon = scene.instantiate()
	get_parent().add_child(wagon)
	wagon.global_position = Vector2(last_spawn_x, 0)
	wagons.append(wagon)
	
	await get_tree().process_frame
	if wagon.has_node("Bat"):
		var bat_container = wagon.get_node("Bat")
		if bat_container.get_child_count() > 0:
			var bat = bat_container.get_child(0)
			if bat.has_method("initialize"):
				bat.initialize()

	# Update spawn point based on wagon width
	var width = wagon.get_node("Marker2D").position.x if wagon.has_node("Marker2D") else 2560
	last_spawn_x += width
