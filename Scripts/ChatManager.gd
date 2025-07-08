extends Control
var invitacion_recibida = ""
var match_id = ""
var oponent_id = ""
var my_id = ""
var players_by_id = {}
var current_popup: ConfirmationDialog = null
var verdaderaForma_instance: Node = null

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
			
		"online-players":
			print("DEBUG players list → ", response.data)
			var raw = response.data
			var list = []
			if typeof(raw) == TYPE_DICTIONARY:
				if raw.has("users"):
					list = raw.users
				elif raw.has("players"):
					list = raw.players
				else:
					for key in raw.keys():
						list.append(raw[key])
			elif typeof(raw) == TYPE_ARRAY:
				list = raw
			players_by_id.clear()
			var names = []
			for entry in list:
				if typeof(entry) == TYPE_DICTIONARY and entry.has("id") and entry.has("name"):
					players_by_id[entry.id] = entry.name
					names.append(entry.name)
				elif typeof(entry) == TYPE_STRING:
					names.append(entry)
				else:
					print("⚠️ Entrada inesperada en lista de jugadores:", entry)

	# Asegúrate de incluirte si estás ausente
			if not names.has(mi_nombre):
				names.insert(0, mi_nombre)
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
		#match making
		"match-request-received":
			var from_player = response.data.playerId
			
			_show_ready_popup(from_player)
		"match-rejected":
			var from = players_by_id[response.data.playerId]
			_sendToChatDisplay("%s rechazó tu solicitud de partida." % from)
			
		"match-accepted":
			var connect_event = {
			"event": "connect-match"
			}
			_client.send(JSON.stringify(connect_event))
		"players-ready":
			print("Jugadores listos, enviando ping...")
			var ping_event = {
				"event": "ping-match"
			}
			_client.send(JSON.stringify(ping_event))
			
		"match-start":
			_sendToChatDisplay("Partida iniciada.")
			_start_game()
		"receive-game-data":
			var received_data = response.data
			
			if verdaderaForma_instance and verdaderaForma_instance.has_method("apply_remote_event"):
				verdaderaForma_instance.apply_remote_event(response.data)
			if received_data.has("subEvent") and received_data.subEvent == "defeat":
				receiveData(received_data)
				
		"send-match-request":
			$VBoxContainer2/RejectButton.visible=true
			
		
		"cancel-match-request":
			_sendToChatDisplay("El jugador %s canceló la solicitud de partida." % response.data.playerId)
			if current_popup:
				current_popup.queue_free()
				current_popup = null
				
		"match-rejected":
			_sendToChatDisplay("%s rechazó tu solicitud de partida." % response.data.playerId)
			if current_popup:
				current_popup.queue_free()
				current_popup = null
		"finish-game":
			# Este evento lo recibes cuando ERES el ganador
			
			get_tree().change_scene_to_file("res://Scenes/FinalGanar.tscn")
		"game-ended":
			print(response.msg)
			_sendToChatDisplay(response.msg)
			verdaderaForma_instance.show_end_popup(false)
			
		"close-match":
			print(response.msg)

func receiveData(datos):
	var msg = ""
	if datos.has("defeat"):
		msg = {
			"event": "finish-game"
	}
	_client.send(JSON.stringify(msg))
	if datos.has("rocket"):
		get_parent().player.energy -= datos["rocket"]
	if datos.has("HP"):
		get_parent().get_node("UI/enemy").set_energy(datos["HP"])
		
		

func _start_game():
	var juego = preload("res://Scenes/MultiPlayerPlay.tscn").instantiate()
	verdaderaForma_instance = juego  # Ahora guardas la referencia

	juego.chat_instance = self  # Si quieres que el juego tenga acceso al chat

	get_tree().root.add_child(juego)
	self.visible = false
	get_tree().current_scene = juego

	
func _send_death():
	var message = {
		"event": "send-game-data",
		"data": {
			"data": "defeat"
		}
	}
	_client.send(JSON.stringify(message))

func on_opponent_defeated():
	var event = {
		"event": "finish-game"
	}
	_client.send(JSON.stringify(event))
	
	
func _show_ready_popup(from_player: String):
	var popup = ConfirmationDialog.new()
	popup.dialog_text = "%s quiere comenzar una partida. ¿Aceptar?" % players_by_id[from_player]
	popup.get_ok_button().text = "Aceptar"
	popup.get_cancel_button().text = "Rechazar"
	
	popup.connect("confirmed", func ():
		var accept_event = {
			"event": "accept-match",
			"data": {
				"id": from_player
			}
		}
		_client.send(JSON.stringify(accept_event))
		
		var connect_event = {
			"event": "connect-match"
		}
		_client.send(JSON.stringify(connect_event))
	)
	popup.connect("canceled", func ():
		var reject_event = {
			"event": "reject-match"
		}
		_client.send(JSON.stringify(reject_event))
	)
	current_popup = popup
	add_child(popup)
	popup.popup_centered()
func _send_rematch_request():
	var event = {
		"event": "send-rematch-request"
	}
	_client.send(JSON.stringify(event))

func _send_quit_match():
	var event = {
		"event": "quit-match"
	}
	_client.send(JSON.stringify(event))
	


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
		"event": 'online-players'
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
	var selected_indices = player_list.get_selected_items() # Esto devuelve los índices seleccionados
	
	if selected_indices.size() == 0:
		_sendToChatDisplay("Selecciona un jugador primero.")
		return

	var selected_item_index = selected_indices[0]
	var target_name = player_list.get_item_text(selected_item_index) # Obtiene el nombre del jugador

	# --- AQUÍ ES DONDE CAMBIA LA LÓGICA ---
	# Buscar el ID real del oponente usando el nombre que acabamos de obtener.
	var target_id: String = ""
	for id_key in players_by_id.keys(): # Iterar sobre las claves (IDs) del diccionario
		if players_by_id[id_key] == target_name: # Si el nombre asociado a este ID coincide con el nombre objetivo
			target_id = id_key # Hemos encontrado el ID
			break # Salir del bucle una vez encontrado

	if target_id.is_empty():
		_sendToChatDisplay("Error: No se pudo encontrar el ID del jugador '%s'. La lista de IDs puede estar desactualizada." % target_name)
		return

	# Ahora que tenemos el ID correcto, lo enviamos.
	send_ready_request(target_id)
	_sendToChatDisplay("Solicitud de partida enviada a %s (ID: %s)" % [target_name, target_id])


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

# En ChatManager.gd, después de tus funciones existentes, pero al mismo nivel de indentación:

func _handle_game_end(is_winner: bool, message: String):
	_sendToChatDisplay(message)
	print("DEBUG: Partida terminada. Ganador:", is_winner, " Mensaje:", message)
	verdaderaForma_instance.show_victory_screen()
	
	if verdaderaForma_instance:
		if is_winner:
			if verdaderaForma_instance.has_method("show_victory_screen"):
				verdaderaForma_instance.show_victory_screen()
			else:
				print("ADVERTENCIA: verdaderaForma_instance no tiene el método 'show_victory_screen'.")
		else: # Es el perdedor
			if verdaderaForma_instance.has_method("show_end_popup"):
				verdaderaForma_instance.show_end_popup(false) # false indica que no es el ganador
			else:
				print("ADVERTENCIA: verdaderaForma_instance no tiene el método 'show_end_popup'.")
	else:
		print("ADVERTENCIA: verdaderaForma_instance es null al intentar manejar el fin de la partida.")

	# Opcional: Después de mostrar las pantallas, podrías añadir un retardo
	# y luego volver al lobby o liberar la escena del juego.
	# Por ahora, se mantiene la lógica de "close-match" para la limpieza y vuelta al lobby.





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


func _on_actualizar_pressed() -> void:
	_sendToChatDisplay("Solicitando lista actual de jugadores...")
	_sendGetUserListEvent()
	_sendToChatDisplay("Lista actualizada!!!!")

func send_ready_request(oponent_id: String):
	var dataToSend = {
		"event": 'send-match-request',
		"data": {
			"playerId": oponent_id
		}
	}
	_client.send(JSON.stringify(dataToSend))
	
func _on_invitar_pressed() -> void:
	_on_invite_button_pressed()
	
	
	
