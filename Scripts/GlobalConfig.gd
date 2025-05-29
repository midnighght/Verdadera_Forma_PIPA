extends Node

var brillo := 1.0  # Valor entre 0 (oscuro) y 1 (claro)
var volumen := 1.0
var config_path := "user://config.cfg"
var config := ConfigFile.new()

func _ready():
	cargar_config()

func guardar_config():
	config.set_value("audio", "volumen", volumen)
	config.set_value("pantalla", "brillo", brillo)
	var error = config.save(config_path)
	if error != OK:
		print("Error guardando configuración:", error)
	else:
		print("Configuración guardada")

func cargar_config():
	var error = config.load(config_path)
	if error == OK:
		volumen = config.get_value("audio", "volumen", 1.0)
		brillo = config.get_value("pantalla", "brillo", 1.0)
		print("Configuración cargada desde archivo")
	else:
		print("No se encontró configuración previa, usando valores por defecto")

func aplicar_config(color_rect_node):
	# Ajusta volumen en bus 0
	AudioServer.set_bus_volume_db(0, linear_to_db(volumen))
	# Ajusta brillo modificando color.a del ColorRect (invirtiendo para lógica intuitiva)
	var color = color_rect_node.color
	color.a = 1.0 - brillo  # Invertir para que brillo=1 sea claro (alfa=0)
	color_rect_node.color = color
