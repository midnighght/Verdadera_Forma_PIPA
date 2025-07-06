extends Control

var _host_base = "ws://ucn-game-server.martux.cl:4010"
@onready var _client: WebSocketClient = $WebSocketClient

@onready var chat_display: TextEdit = $VBoxContainer/MainPanel/ChatDisplay
@onready var player_list: ItemList = $VBoxContainer/MainPanel/VBoxContainer/UserList

@onready var input_message: LineEdit = $VBoxContainer/Commands/InputMessage
@onready var send_button: Button = $VBoxContainer/Commands/SendButton
@onready var start_button: Button = $VBoxContainer/MainPanel/VBoxContainer/StartGameButton

var oponent_id = ""
var svgame_instance: Node = null
var my_id = ""
var players_by_id = {}

var current_popup: ConfirmationDialog = null

var my_name = ""  # Guarda el nombre local para enviar en la URL y en la lista

func _ready():
	# Por ejemplo, pide el nombre o configúralo por UI antes de conectar
	# Aquí solo un ejemplo para testear
	my_name = "loboauro"  # O que venga de input o config
	_connect_to_server()

func _connect_to_server():
	var url = "%s/?gameId=D&playerName=%s" % [_host_base, my_name]
	print("Conectando a URL:", url)
	var err = _client.connect_to_url(url)
	if err != OK:
		_sendToChatDisplay("Error conectando al servidor: %s" % err)
		return

	_client.connected_to_server.connect(_on_web_socket_client_connected_to_server)
	_client.message_received.connect(_on_web_socket_client_message_received)
	_client.connection_closed.connect(_on_web_socket_client_connection_closed)

func _on_web_socket_client_connection_closed():
	var ws = _client.get_socket()
	_sendToChatDisplay("Client disconnected. Code: %s, Reason: %s" % [ws.get_close_code(), ws.get_close_reason()])

func _on_web_socket_client_connected_to_server():
	print("Conectado al servidor. Enviando login con gameKey...")
	var login_event = {
		"event": "login",
		"data": { "gameKey": "UZ78ZY" }  # Clave de acceso correcta
	}
	_client.send(JSON.stringify(login_event))
	_sendToChatDisplay("Conexión establecida. Login enviado.")

func _on_web_socket_client_message_received(message: String):
	var response = JSON.parse_string(message)
	if response == null:
		_sendToChatDisplay("[Error] JSON no válido recibido")
		return
	
	if not response.has("event"):
		_sendToChatDisplay("[Error] Evento no especificado en mensaje: %s" % message)
		return

	print("Evento recibido:", response.event)
	
	match(response.event):
		"connected-to-server":
			my_id = response.data.id
			_sendToChatDisplay("Conectado al servidor con ID: %s" % my_id)
			
		"login":
			_sendToChatDisplay("Login exitoso. Solicitando lista de jugadores...")
			_sendGetUserListEvent()
			# Agrega tu nombre a la lista para que te veas en ella
			_addUserToList(my_name)
		
		"online-players":
			players_by_id.clear()
			var names = []
			for data in response.data:
				players_by_id[data.id] = data.name
				names.append(data.name)
			_updateUserList(names)
			
		"player-connected":
			if response.data.has("id") and response.data.has("name"):
				players_by_id[response.data.id] = response.data.name
				_addUserToList(response.data.name)
				
		"player-disconnected":
			if response.data.has("id"):
				var id = response.data.id
				if players_by_id.has(id):
					_deleteUserFromList(id)
					players_by_id.erase(id)
		
		"public-message":
			_sendToChatDisplay("%s: %s" % [response.data.playerName, response.data.playerMsg])
		
		# Aquí puedes agregar más eventos según tu juego...
		
		_:
			print("Evento no manejado:", response.event)

# UI handlers
func _on_input_submitted(message:String): 
	if input_message.text == "":
		return
	_sendMessage(message)
	input_message.text = ""

func _on_send_pressed():
	if input_message.text == "":
		return
	_sendMessage(input_message.text)
	input_message.text = ""

func _sendMessage(message: String, userId: String = ''):
	var action = "send-private-message" if userId != "" else "send-public-message"
	var dataToSend = {
		"event": action,
		"data": {
			"message": message
		}
	}
	_client.send(JSON.stringify(dataToSend))

func _sendGetUserListEvent():
	var dataToSend = {
		"event": "online-players"  # Evento correcto para solicitar lista usuarios
	}
	_client.send(JSON.stringify(dataToSend))

func _updateUserList(users: Array):
	player_list.clear()
	for user in users:
		player_list.add_item(user)

func _addUserToList(user: String):
	# Evitar duplicados
	for i in range(player_list.get_item_count()):
		if player_list.get_item_text(i) == user:
			return
	player_list.add_item(user)

func _deleteUserFromList(userId: String):
	for i in range(player_list.get_item_count()):
		if player_list.get_item_text(i) == players_by_id.get(userId, ""):
			player_list.remove_item(i)
			return

func _on_user_list_item_selected(index: int) -> void:
	var selected_name = player_list.get_item_text(index)
	oponent_id = get_player_id_by_name(selected_name)
	start_button.visible = true
	print("Oponente seleccionado:", oponent_id)

func get_player_id_by_name(name: String) -> String:
	for id in players_by_id.keys():
		if players_by_id[id] == name:
			return id
	return ""

func _on_start_game_button_pressed() -> void:
	if oponent_id != "":
		send_ready_request(oponent_id)

func send_ready_request(oponent_id: String):
	var dataToSend = {
		"event": "send-match-request",
		"data": {
			"playerId": oponent_id
		}
	}
	_client.send(JSON.stringify(dataToSend))

func _on_cancel_game_button_pressed() -> void:
	var dataToSend = {
		"event": "cancel-match-request",
		"data": {
			"playerId": oponent_id
		}
	}
	_client.send(JSON.stringify(dataToSend))

func _sendToChatDisplay(msg):
	print(msg)
	chat_display.text += str(msg) + "\n"
