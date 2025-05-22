extends Control
@onready var fondo_brillo = $ColorRect  # Ajusta la ruta si tu nodo tiene otro nombre o está en otra rama


func aplicar_brillo(valor: float) -> void:
	var color = fondo_brillo.color
	color.a = 1- valor  # Valor entre 0 (claro) y 1 (oscuro)
	fondo_brillo.color = color
	
func _ready():
	var brillo_guardado = GlobalConfig.brillo  # O cualquier variable donde guardes el valor
	aplicar_brillo(brillo_guardado)


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/juego.tscn")


func _on_asincronico_pressed() -> void:
	pass # Replace with function body.


func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://Prefabs/UI/opciones.tscn")


func _on_salir_pressed() -> void:
	get_tree().quit()
