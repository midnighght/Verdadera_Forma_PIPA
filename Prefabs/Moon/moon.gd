extends Node2D

@onready var tiempo = $Timer
@onready var luz = $"Light Dynamics"
var encendida = false

func _ready():
	randomize()
	luz.visible = false
	tiempo.timeout.connect(_on_timer_timeout)
	esperar_proximo_cambio()

func _on_timer_timeout():
	encendida = !encendida
	luz.visible = encendida
	print("LUZ encendida:", encendida)
	esperar_proximo_cambio()

func esperar_proximo_cambio():
	if encendida:
		tiempo.wait_time = randf_range(10.0, 20.0)  # tiempo prendida
		print("luz con sombras por ",tiempo.wait_time, "segundos")
	else:
		tiempo.wait_time = randf_range(3.0, 6.0) 
		print("luz prendida por ",tiempo.wait_time, "segundos")   # tiempo apagada
	tiempo.start()
	
