extends Node2D

func _ready():
	get_tree().paused = false
	hide()

func death():
	pause_death()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/MainTitle.tscn")
	
func _on_salir_pressed() -> void:
	get_tree().quit()
	
func resume():
	hide()
	get_tree().paused = false

func pause_death():
	get_tree().paused = true
	show()
