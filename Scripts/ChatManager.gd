
extends Control
var invitacion_recibida = ""
var match_id = ""
var oponente = ""
@export var mi_nombre: String =""

# URL de conexión
var _host : String=""
@onready var _client: WebSocketClient = $WebSocketClient

# Referencias a los nodos de la UI
@onready var chat_display: TextEdit = $VBoxContainer/MainPanel/ChatDisplay
@onready var player_list: ItemList = $VBoxContainer/MainPanel/UserList

@onready var input_message: LineEdit = $VBoxContainer/Commands/InputMessage
@onready var send_button: Button = $VBoxContainer/Commands/SendButton



# Señales


# Cuando se cierra la conexión
func _ready():
	print("Mi nombre →", mi_nombre)

	_host = "ws://ucn-game-server.martux.cl:4010/?gameId=D&playerName=%s" % mi_nombre
	_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_client.message_received.connect(_on_web_socket_client_message_received) # ← FALTA ESTA
	_client.connection_closed.connect(_on_web_socket_client_connection_closed)

func _on_web_socket_client_connection_closed():
	var ws = _client.get_socket()
	_sendToChatDisplay("Client just disconnected with code: %s, reason: %s" % [ws.get_close_code(), ws.get_close_reason()])

# Cuando se conecta al servidor
func _on_web_socket_client_connected_to_server():
	_sendToChatDisplay("Conexión establecida con el servidor. Enviando login...")
	print("DEBUG: conectado al servidor desde cliente")
	
	# Enviar login con gameKey
	var login_payload = {
		"event": "login",
		"data": {
			"gameKey": "UZ78ZY"
		}
	}
	print("Payload login → ", JSON.stringify(login_payload))
	_client.send(JSON.stringify(login_payload))
	
	_sendGetUserListEvent()

# Gestor de mensajes del servidor
func _on_web_socket_client_message_received(message: String):
	var response = JSON.parse_string(message)
	
	if typeof(response) == TYPE_DICTIONARY and response.has("event"):
		var event_name = response["event"]
		match event_name:
			"connected-to-server":
				_sendToChatDisplay("You are connected to the server!")
				print("EVENTO RECIBIDO →connected-to-server")
			
			"login":
				_sendToChatDisplay("¡Login exitoso! Obteniendo lista de usuarios...")
				print("EVENTO RECIBIDO →login")
				_sendGetUserListEvent()
			
			"player-connected":
				print("EVENTO RECIBIDO →player-connected")
				print("DEBUG - Tipo de response.data:", typeof(response["data"]))
				print("DEBUG - Contenido de response.data:", JSON.stringify(response["data"]))
			
			"player-status-changed":
				print("EVENTO RECIBIDO →player-status-changed")
			
			"player-disconnected":
				print("EVENTO RECIBIDO →player-disconnected")
			
			"send-public-message":
				print("EVENTO RECIBIDO →send-public-message")
			
			"public-message":
				var msg = response["data"]["playerName"] + ": " + response["data"]["playerMsg"]
				print("EVENTO RECIBIDO →public-message")
				_sendToChatDisplay(msg)
			
			_:
				print("Evento desconocido:", event_name)
	else:
		print("Respuesta inválida recibida:", message)


# Señales de la UI
# Cuando se envia un mensaje desde el input
func _on_input_submitted(message:String): 
	if input_message.text == "":
		return
		
	_sendMessage(message)
	input_message.text = ""

# Cuando se presiona el botón de "SEND"
func _on_send_pressed():
	if input_message.text == "":
		return

	_sendMessage(input_message.text)
	input_message.text = ""

# Cuando se pulsa el botón de "CONNECT TO SERVER"
func _on_connect_toggled(pressed):
	if not pressed:
		_client.close()
		return
	_sendToChatDisplay("Connecting to host: %s." % [_host])
	var err = _client.connect_to_url(_host)
	if err != OK:
		_sendToChatDisplay("Error connecting to host: %s" % [_host])
		return

# Funciones de la clase
# Agrega un mensaje en la pantalla de chat
func _sendToChatDisplay(msg):
	print(msg)
	chat_display.text += str(msg) + "\n"

# Envía un mensaje a un usuario o al chat grupal y manda la solicitud al servidor
func _sendMessage(message: String, userId: String = ''):
	var action
	if (userId != ''):
		action = 'send-private-message'
	else:
		action = 'send-public-message'
		
	var dataToSend = {
		"event": action,
		"data": {
			"message": message
		}
	}

	_client.send(JSON.stringify(dataToSend))

# Solicita la lista de usuarios activos al servidor
func _sendGetUserListEvent():
	var dataToSend = {
		"event": 'get-connected-players'
	}
	_client.send(JSON.stringify(dataToSend))

# Actualiza la lista de usuarios de la interfaz gráfica
func _updateUserList(users: Array):
	player_list.clear()
	for user in users:
		player_list.add_item(user)

# Agrega un jugador al listado
func _addUserToList(user: String):
	player_list.add_item(user)

# Elimina un jugador del listado
func _deleteUserFromList(userId: String):
	var playerListCount = player_list.item_count
	for i in range(0, playerListCount):
		if(player_list.get_item_text(i) == userId):
			player_list.remove_item(i)
			return


func _on_invite_button_pressed() -> void:
	var selected = player_list.get_selected_items()
	if selected.size() == 0:
		_sendToChatDisplay("Selecciona un jugador primero.")
		return

	var target_name = player_list.get_item_text(selected[0])
	var payload = {
		"event": "send-match-request",
		"data": {
			"playerName": target_name

		}
	}
	_client.send(JSON.stringify(payload))
	_sendToChatDisplay("Solicitud enviada a %s" % target_name)

func _on_accept_button_pressed():
	var payload = {
		"event": "accept-match",
		"data": {
			"playerName": invitacion_recibida
		}
	}
	_client.send(JSON.stringify(payload))
	_sendToChatDisplay("Aceptaste la partida con %s" % invitacion_recibida)
	_ocultar_botones_match()

func _on_reject_button_pressed():
	var payload = {
		"event": "reject-match",
		"data": {
			"playerName": invitacion_recibida
		}
	}
	_client.send(JSON.stringify(payload))
	_sendToChatDisplay("Rechazaste la partida con %s" % invitacion_recibida)
	_ocultar_botones_match()
	
func _ocultar_botones_match():
	$VBoxContainer2.visible = false
	
	invitacion_recibida = ""


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/PONERnombreUSUARIO.tscn")
