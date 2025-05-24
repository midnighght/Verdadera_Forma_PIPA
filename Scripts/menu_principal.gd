extends Control

func _on_singleplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/TestPlay.tscn")

func _on_multiplayer_pressed() -> void:
	pass

func _on_config_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/opciones.tscn")

<<<<<<< Updated upstream
func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/juego.tscn")


func _on_asincronico_pressed() -> void:
	pass # Replace with function body.


func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://Prefabs/UI/opciones.tscn")


func _on_salir_pressed() -> void:
=======
func _on_quit_pressed() -> void:
>>>>>>> Stashed changes
	get_tree().quit()
