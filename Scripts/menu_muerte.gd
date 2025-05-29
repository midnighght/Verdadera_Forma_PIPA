extends Node2D


func _on_salir_pressed() -> void:
	get_tree().quit()


func _on_menu_principal_pressed() -> void:
	var escena = load("res://Scenes/MainTitle.tscn")
	if escena:
		get_tree().change_scene_to_packed(escena)
	else:
		print("No se pudo cargar la escena")
