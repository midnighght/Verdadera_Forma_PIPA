extends Node2D

@onready var fondo_brillo = $ColorRect  # Nodo que controla brillo
@onready var slider_volumen = $VBoxContainer3/Sonido
@onready var slider_brillo = $VBoxContainer4/Brillo

func _ready():
	slider_volumen.value = GlobalConfig.volumen
	slider_brillo.value = GlobalConfig.brillo
	GlobalConfig.aplicar_config(fondo_brillo)

func _on_confirmar_pressed() -> void:
	GlobalConfig.volumen = slider_volumen.value
	GlobalConfig.brillo = slider_brillo.value
	GlobalConfig.guardar_config()
	GlobalConfig.aplicar_config(fondo_brillo)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainTitle.tscn")
