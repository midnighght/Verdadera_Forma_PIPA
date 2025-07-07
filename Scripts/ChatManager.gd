extends Control

var invitacion_recibida = ""
var match_id = ""
var oponente = ""
var my_id = ""
var players_by_id = {}

@export var mi_nombre: String =""


var _host: String = ""
@onready var _client: WebSocketClient = $WebSocketClient

@onready var chat_display: TextEdit = $VBoxContainer/MainPanel/ChatDisplay
@onready var player_list: ItemList = $VBoxContainer/MainPanel/UserList

@onready var input_message: LineEdit = $VBoxContainer/Commands/InputMessage
@onready var send_button: Button = $VBoxContainer/Commands/SendButton



var current_popup: ConfirmationDialog = null

func _ready():
	# Conectar señales del WebSocketClient
	_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_client.message_received.connect(_on_web_socket_client_message_received)
	_client.connection_closed.connect(_on_web_socket_client_connection_closed)
	
	# Formar la URL con gameId y playerName
	_host = "ws://ucn-game-server.martux.cl:4010/?gameId=D&playerName=%s" % mi_nombre
	
	# Conectar al servidor
	var err = _client.connect_to_url(_host)
	if err != OK:
		_sendToChatDisplay("Error al conectar al host: %s" % _host)


# Señales WebSocket
func _on_web_socket_client_connected_to_server():
	_sendToChatDisplay("Conexión establecida con el servidor. Enviando login...")
	
	var login_payload = {
		"event": "login",
		"data": {
			"gameKey": "UZ78ZY"
		}
	}
	_client.send(JSON.stringify(login_payload))
	
	_sendGetUserListEvent()

func _on_web_socket_client_message_received(message: String):
	var response = JSON.parse_string(message)
	
	if response == null:
		_sendToChatDisplay("[Error] JSON no válido recibido")
		return
	

	print("Evento recibido: %s | Datos: %s" % [response.event, str(response.data)])

	
	match(response.event):
		"connected-to-server":
			my_id = response.data.id
			_sendToChatDisplay("You are connected to the server!")

	match response.event:
		"connected-to-server":
			_sendToChatDisplay("Conectado al servidor correctamente.")
			

		"login":
			# Aquí puedes hacer algo con response.data si lo necesitas
			_sendToChatDisplay("Login exitoso.")
			# Solicita la lista de jugadores luego de login
			_sendGetUserListEvent()
			
		"public-message":
			_sendToChatDisplay("%s: %s" % [response.data.playerName, response.data.playerMsg])
		
		"send-public-message":
			_sendToChatDisplay("Tú: %s" % response.data.message)
		
		"public-message":
			_sendToChatDisplay("%s: %s" % [response.data.playerName, response.data.playerMsg])
			
		"get-connected-players", "online-players":
			if typeof(response.data) == TYPE_ARRAY:
				_updateUserList(response.data)
			elif typeof(response.data) == TYPE_DICTIONARY and response.data.has("users"):
				_updateUserList(response.data.users)
			else:
				_sendToChatDisplay("[Aviso] Lista de usuarios con formato inesperado")
				
		"player-connected":
			if typeof(response.data) == TYPE_DICTIONARY and response.data.has("name"):
				_addUserToList(response.data.name)
			else:
				_sendToChatDisplay("[Error] 'player-connected' mal formateado: %s" % str(response.data))
				
			_addUserToList(mi_nombre)
		"send-public-message":
			_sendToChatDisplay("Tú: %s" % response.data.message)
			
		"public-message":
			_sendToChatDisplay("%s: %s" % [response.data.playerName, response.data.playerMsg])
		"get-connected-players":
			var names = []
			players_by_id.clear()
			for data in response.data:
				var id = data.id
				var name = data.name
				print(name)
				players_by_id[id] = name
				names.append(name)
			_updateUserList(names)
		"player-data":
			var names = []
			for user in response.data:
				names.append(user.name)
			_updateUserList(names)
		"player-connected":
			
			_addUserToList(response.data.name)
			players_by_id[response.data.id] = response.data.name
			

		"player-disconnected":
			if typeof(response.data) == TYPE_DICTIONARY and response.data.has("name"):
				_deleteUserFromList(response.data.name)
			else:
				_sendToChatDisplay("[Error] 'player-disconnected' mal formateado: %s" % str(response.data))
		
		"match-request-received":
			_sendToChatDisplay("¡%s quiere jugar contigo!" % response.data.name)
			invitacion_recibida = response.data.name
			$VBoxContainer2.visible = true
		
		"match-start":
			_sendToChatDisplay("¡La partida ha comenzado con %s!" % response.data.opponent.playerName)
			match_id = response.data.matchId
			oponente = response.data.opponent.name
			
			get_tree().change_scene_to_file("res://Scenes/SinglePlayerPlay.tscn")
		
		
			_sendToChatDisplay("Evento no manejado: %s" % response.event)

func _on_web_socket_client_connection_closed():
	_sendToChatDisplay("Conexión cerrada con el servidor.")

# UI - Enviar mensajes
func _on_input_submitted(message: String):
	if input_message.text.strip_edges() == "":
		return
	_sendMessage(message)
	input_message.text = ""

func _on_send_pressed():
	if input_message.text.strip_edges() == "":
		return
	_sendMessage(input_message.text)
	input_message.text = ""

# Enviar mensaje público o privado (no se implementa privado aquí)
func _sendMessage(message: String, userId: String = ""):
	var action = "send-public-message"
	
	var dataToSend = {
		"event": action,
		"data": {
			"message": message
		}
	}
	_client.send(JSON.stringify(dataToSend))

# Solicitar lista usuarios conectados
func _sendGetUserListEvent():
	var dataToSend = {
		"event": "get-connected-players"
	}
	_client.send(JSON.stringify(dataToSend))

# Actualizar lista UI usuarios
func _updateUserList(users: Array):
	player_list.clear()
	players_by_id.clear()  # Limpia para recargar
	for user in users:
		if typeof(user) == TYPE_DICTIONARY:
			players_by_id[user.id] = user.name
			player_list.add_item(user.name)
		elif typeof(user) == TYPE_STRING:
			# Si viene solo un array de strings (nombres)
			# No tienes id, solo el nombre
			player_list.add_item(user)


func _addUserToList(user: String):
	player_list.add_item(user)

func _deleteUserFromList(user: String):
	for i in range(player_list.item_count):
		if player_list.get_item_text(i) == user:
			player_list.remove_item(i)
			break

# Botones para invitación y respuesta
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

# Mensajes al chat
func _sendToChatDisplay(msg: String):
	print(msg)
	chat_display.text += msg + "\n"

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/PONERnombreUSUARIO.tscn")
