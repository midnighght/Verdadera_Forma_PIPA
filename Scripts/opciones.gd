extends Node2D


@onready var slider = $Slider
@onready var Opciones = $"."  # Ajusta esta ruta al nodo que quieres atenuar


func _ready():
	$VBoxContainer3/Sonido.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	



func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menuPrincipal.tscn")


func _on_confirmar_pressed() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db($VBoxContainer3/Sonido.value))
	
	var color = Opciones.modulate
	color.a = $VBoxContainer4/Brillo.value  # Modificamos solo la opacidad (alfa)
	Opciones.modulate = color
	pass # Replace with function body.
	
	
	


	
	
	
	
