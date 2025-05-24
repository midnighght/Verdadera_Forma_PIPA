extends Node2D
@onready var jugador= get_node("Jugador")
@onready var enemigo= get_node("Enemigo")

func daño_al_jugador()->void:
	if enemigo.is_on_group(jugador):
		jugador.take_damage(300)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://menuPrincipal.tscn")
	pass # Replace with function body.
