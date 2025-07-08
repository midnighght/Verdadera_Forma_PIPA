extends Node2D
func _ready():
	print("🚀 El juego se ha cargado correctamente")

func show_victory_screen():
	print("¡Victoria!")

func show_end_popup(success: bool):
	print("Fin de partida. ¿Ganaste?", success)
