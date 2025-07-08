extends Control


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/PONERnombreUSUARIO.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
