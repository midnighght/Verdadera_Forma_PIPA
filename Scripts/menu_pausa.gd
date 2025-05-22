extends Control

func _ready():
	# Asegurarse que el menú está oculto al inicio
	hide()
	# Detener cualquier animación que pueda estar activa
	$AnimationPlayer.stop(true)
	# Forzar estado inicial no pausado
	get_tree().paused = false
	# Resetear la animación sin reproducirla
	$AnimationPlayer.seek(0, true)

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("MenuInGame")
	# Ocultar el menú después de la animación si es necesario
	await $AnimationPlayer.animation_finished
	hide()

func pause():
	# Mostrar el menú antes de la animación
	show()
	get_tree().paused = true
	$AnimationPlayer.play("MenuInGame")

func testEsc():
	if Input.is_action_just_pressed("escape"):
		if get_tree().paused:
			resume()
		else:
			pause()

# Resto de tus funciones permanecen igual...
func _on_continuar_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	get_tree().paused = false  # Asegurar que no quedó pausado
	get_tree().reload_current_scene()

func _on_menu_principal_pressed() -> void:
	get_tree().quit()

func _process(delta):
	testEsc()
