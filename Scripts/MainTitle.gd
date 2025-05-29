extends Control

@onready var fondo_brillo = $ColorRect  # Tu ColorRect que cubre pantalla

func _ready():
	GlobalConfig.aplicar_config(fondo_brillo)
	
func _on_singleplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestPlay.tscn")

func _on_multiplayer_pressed() -> void:
	pass

func _on_config_pressed() -> void:
	get_tree().change_scene_to_file("res://Prefabs/UI/opciones.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
