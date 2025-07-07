extends Node2D

@export var disabled: bool = false

func _ready():
	disabled = false
	# Forzar estado inicial no pausado
	get_tree().paused = false
	# Asegurarse que el menú está oculto al inicio
	hide()
	# Detener cualquier animación que pueda estar activa
	#$MenuPausa/AnimationPlayer.stop(true)
	# Resetear la animación sin reproducirla
	#$MenuPausa/AnimationPlayer.seek(0, true)

func _input(event):
	if disabled:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume()
		else:
			pause()

func disable_pause_menu():
	disabled = true
	
func enable_pause_menu():
	disabled = false

# Funciones botones
func _on_continuar_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/MainTitle.tscn")

func resume():
	if disabled:
		return
	#$MenuPausa/AnimationPlayer.play_backwards("MenuInGame")
	# Ocultar el menú después de la animación si es necesario
	#await $MenuPausa/AnimationPlayer.animation_finished
	hide()
	get_tree().paused = false

func pause():
	if disabled:
		return
	# Mostrar el menú antes de la animación
	get_tree().paused = true
	show()
	#$MenuPausa/AnimationPlayer.play("MenuInGame")
