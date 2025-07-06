extends Control

@onready var input_message: LineEdit = $HBoxContainer/InputMessage
@onready var send_button: Button = $HBoxContainer/SendButton

func _ready():
	send_button.pressed.connect(_on_send_button_pressed)

func _on_send_button_pressed():
	var nombre = input_message.text.strip_edges()
	if nombre == "":
		return

	# Verificar si ya existe una instancia de chat-window
	for child in get_tree().root.get_children():
		if child.name == "chat-window":
			print("chat-window ya está activa")
			return  # Evitar duplicar la escena

	# Cargar la escena solo si no existe ya
	var nueva_escena = load("res://Scenes/chat-window.tscn").instantiate()
	nueva_escena.name = "chat-window"  # Esto es importante para que la verificación funcione bien
	nueva_escena.mi_nombre = nombre

	get_tree().root.call_deferred("add_child", nueva_escena)
	get_tree().current_scene.call_deferred("free")
	get_tree().call_deferred("set_current_scene", nueva_escena)


##func _preguntar_nombre():
	
	##onready var mi_nombre
