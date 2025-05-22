extends Node2D

@onready var slider = $Slider
@onready var Opciones = $"."  # Ajusta si es necesario

var config_path := "user://config.cfg"
var config := ConfigFile.new()

func _ready():
	$VBoxContainer3/Sonido.value = GlobalConfig.volumen
	$VBoxContainer4/Brillo.value = GlobalConfig.brillo
	GlobalConfig.aplicar_config(Opciones)

func aplicar_config(volumen: float, brillo: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volumen))
	var color = Opciones.modulate
	color.a = brillo
	Opciones.modulate = color

func guardar_config():
	config.set_value("audio", "volumen", $VBoxContainer3/Sonido.value)
	config.set_value("pantalla", "brillo", $VBoxContainer4/Brillo.value)
	var error = config.save(config_path)
	if error != OK:
		print("Error guardando configuración:", error)
	else:
		print("Configuración guardada")

func cargar_config():
	var error = config.load(config_path)
	if error == OK:
		var volumen = config.get_value("audio", "volumen", 1.0)
		var brillo = config.get_value("pantalla", "brillo", 1.0)
		$VBoxContainer3/Sonido.value = volumen
		$VBoxContainer4/Brillo.value = brillo
		aplicar_config(volumen, brillo)
		print("Configuración cargada")
	else:
		print("No se encontró configuración previa")

func _on_confirmar_pressed() -> void:
	GlobalConfig.volumen = $VBoxContainer3/Sonido.value
	GlobalConfig.brillo = $VBoxContainer4/Brillo.value
	GlobalConfig.guardar_config()
	GlobalConfig.aplicar_config(Opciones)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menuPrincipal.tscn")

	


	
	
	
	
