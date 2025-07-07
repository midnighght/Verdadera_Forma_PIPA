extends Control
var invitacion_recibida = ""
var match_id = ""
var oponente = ""
var my_id = ""
var players_by_id = {}
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


# Gestor de mensajes del servidor
func _on_web_socket_client_message_received(message: String):
	var response = JSON.parse_string(message)
	print("Mensaje recibido del servidor:", message)
	if response == null:
		_sendToChatDisplay("[Error] JSON no válido recibido")
		return
	
	
	match(response.event):
		"connected-to-server":
			my_id = response.data.id
			mi_nombre = response.data.name             # opcional si confías en el servidor
			# Construimos la lista inicial sólo contigo
			var names = [mi_nombre]
			players_by_id.clear()
			players_by_id[my_id] = mi_nombre
			_updateUserList(names)

			_sendToChatDisplay("You are connected to the server!")
			
	# Solo cambiar de escena si no se recibió un nombre al instanciar
			
			
		"public-message":
			_sendToChatDisplay("%s: %s" % [response.data.playerName, response.data.playerMsg])
		"send-public-message":
			_sendToChatDisplay("You: %s" % response.data.message)
			
		"get-connected-players", "online-players":
			print("DEBUG players list → ", response.data)

			var raw = response.data
			var list = []
			# Si el payload es un diccionario con lista en “users” o “players”
			if typeof(raw) == TYPE_DICTIONARY:
				if raw.has("users"):
					list = raw.users
				elif raw.has("players"):
					list = raw.players
				else:
			# fallback: convertir todo el diccionario a array de valores
					for key in raw.keys():
						list.append(raw[key])
			elif typeof(raw) == TYPE_ARRAY:
				list = raw

	# Ahora sí procesar el listado uniforme
			players_by_id.clear()
			var names = []
			for entry in list:
				players_by_id[entry.id] = entry.name
				names.append(entry.name)
			_updateUserList(names)


			
		"player-connected":
			_addUserToList(response.data.name)
			players_by_id[response.data.id] = response.data.name
		"player-data":
			var names = []
			for user in response.data:
				names.append(user.name)
			_updateUserList(names)
		"login":
			_sendToChatDisplay("Login exitoso.")
			_sendGetUserListEvent()
		"player-disconnected":
			_deleteUserFromList(response.data.id)
		"match-request-received":
			_sendToChatDisplay("¡%s quiere jugar contigo!" % response.data.name)
			# Guardar el nombre del jugador que te invitó
			invitacion_recibida = response.data.name
	
			# Mostrar botones de aceptar/rechazar
			$VBoxContainer2.visible=true
		
		"match-start":
			_sendToChatDisplay("¡La partida ha comenzado con %s!" % response.data.opponent.name)
			
			# Guardamos datos si quieres hacer algo más adelante
			match_id = response.data.matchId
			oponente = response.data.opponent.name
			
			# Cargar el microjuego (ejemplo con tu escena Pescalo)
			get_tree().change_scene_to_file("res://Scenes/SinglePlayerPlay.tscn")
		

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
