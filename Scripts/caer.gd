extends Area2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	print("¡Un cuerpo entró al área! Nombre del cuerpo: ", body.name)
	if body.is_in_group("jugador"):
			get_tree().change_scene_to_file("res://Scenes/MenuMuerte.tscn")
