extends Node

var brillo := 1.0
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

func aplicar_config(opciones_node):
	# Aplica brillo (modulate alfa) y volumen (AudioServer)
	AudioServer.set_bus_volume_db(0, linear_to_db(volumen))
	var color = opciones_node.modulate
	color.a = brillo
	opciones_node.modulate = color
