extends Node2D

@export var MAX_ENERGY: float = 2.4

@export var LUM: float = 0.0

@export var idle_min_time: float = 30.0
@export var idle_max_time: float = 40.0
var full_moon_duration: float = 5.0
@export var energy_transition_speed: float = 0.8

@onready var timer = $Timer
@onready var light_cast = $"Light Dynamics"/"Light Cast"
@onready var sprite = $Moon

var is_full = false
var transitioning_up = false
var transitioning_down = false

func _ready():
	sprite.play("default")
	light_cast.energy = 0.0
	_set_random_timer()

func _on_timer_timeout():
	if !is_full:
		# Begin waxing phase
		sprite.play("crescent")
		is_full = true
		transitioning_up = true
	else:
		# Begin waning phase
		sprite.play("waning")
		transitioning_down = true
		is_full = false

func _process(delta):
	LUM = light_cast.energy /2.4
	if transitioning_up:
		light_cast.energy += energy_transition_speed * delta
		if light_cast.energy >= MAX_ENERGY:
			light_cast.energy = MAX_ENERGY
			transitioning_up = false
			timer.start(full_moon_duration + randf_range(0.0, 3.0))
	elif transitioning_down:
		light_cast.energy -= energy_transition_speed * delta
		if light_cast.energy <= 0.0:
			light_cast.energy = 0.0
			transitioning_down = false
			_set_random_timer()

func _set_random_timer():
	timer.start(randf_range(idle_min_time, idle_max_time))
