extends Node2D
var estado: bool
@onready var tiempo= $Timer
@onready var luz = $"Light Dynamics"
func _ready():
	luz.visible = false
	tiempo.start(20)
	tiempo.timeout.connect(_on_timer_timeout)


##funcion para señal de lo que pase una vez que 
##ya haya pasado el tiempo
func _on_timer_timeout():
	luz.visible = true
	print("LUZ")
	
