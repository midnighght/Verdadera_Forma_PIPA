extends Node2D
var chat_instance: Control

func _ready():
	print("🚀 El juego se ha cargado correctamente")

func show_victory_screen():
	print("¡Victoria!")
	get_tree().change_scene_to_file("res://Scenes/FinalGanar.tscn")

func show_end_popup(success: bool):
	print("Fin de partida. ¿Ganaste?", success)
	#get_tree().change_scene_to_file("res://Scenes/FinalGanar.tscn")
