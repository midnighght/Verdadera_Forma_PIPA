extends Node2D

@onready var tiempo = $Timer
@onready var luz = $"Light Dynamics"
var encendida = false

func _ready():
	luz.visible = false
	tiempo.wait_time = 20
	tiempo.one_shot = false  # se repetirá automáticamente
	tiempo.timeout.connect(_on_timer_timeout)
	tiempo.start()

func _on_timer_timeout():
	encendida = !encendida         # alterna el estado
	luz.visible = encendida
	print("LUZ:", encendida)
