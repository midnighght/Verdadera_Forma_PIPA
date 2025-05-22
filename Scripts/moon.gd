extends Node2D

@export var rayo_scene: PackedScene
@export var spawn_rate: float = 0.7
@export var rayo_speed: float = 1500
@export var rayo_width: float = 30
@export var movimiento_suavizado: float = 0.1
@export var rango_movimiento_x: float = 500.0
@export var velocidad_movimiento: float = 500.0
@export var rayos_por_disparo: int = 10
@export var separacion_rayos: float = 15
@export var variacion_velocidad: float = 0.2  # 20% de variación
@export var variacion_ancho: float = 0.3     # 30% de variación
@export var delay_entre_rayos: float = 0.05  # Tiempo entre rayos

var direccion: float = 1
var posicion_inicial: Vector2
var patron_disparo: int = 0  # Para alternar patrones
var tiempo_transcurrido: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_timer: Timer = $Rayos/RayoSpawn
@onready var screen_width: float = get_viewport_rect().size.x

func _ready():
	posicion_inicial = position
	spawn_timer.wait_time = spawn_rate
	spawn_timer.start()
	animated_sprite.play("floatar")
	
	# Asegurar que los rayos no excedan el ancho de pantalla
	separacion_rayos = min(separacion_rayos, screen_width / rayos_por_disparo)

func _process(delta):
	# Movimiento horizontal con rebote
	position.x += velocidad_movimiento * direccion * delta
	tiempo_transcurrido += delta
	
	# Cambiar dirección en los límites con pequeña variación aleatoria
	if abs(position.x - posicion_inicial.x) > rango_movimiento_x / 2:
		direccion *= -1
		# Pequeña variación en la posición Y al cambiar direcció
		posicion_inicial.y += randf_range(-20, 20)
	
	# Movimiento vertical suave con onda más compleja
	var movimiento_y = sin(tiempo_transcurrido * 1.5) * 30 + cos(tiempo_transcurrido * 0.7) * 15
	position.y = lerp(position.y, posicion_inicial.y + movimiento_y, movimiento_suavizado)
	
	# Cambiar ocasionalmente el patrón de disparo
	if randf() < 0.005:  # 0.5% de probabilidad cada frame
		patron_disparo = (patron_disparo + 1) % 3

func _on_rayo_spawner_timeout():
	spawn_rayo()
	# Aumentar dificultad progresivamente cada 10 disparos
	if spawn_timer.time_left < 0.1:  # Solo si no está ya corriendo
		spawn_timer.wait_time = max(0.3, spawn_rate * 0.98)  # Reduce gradualmente

func spawn_rayo():
	match patron_disparo:
		0:  # Abanico estándar
			disparar_abanico()
		1:  # Doble abanico cruzado
			disparar_abanico_cruzado()
		2:  # Concentrado en centro
			disparar_concentrado()


func disparar_abanico():
	for i in range(rayos_por_disparo):
		crear_rayo(
			Vector2((i - rayos_por_disparo/2.0) * separacion_rayos, 0),  # position
			randf_range(1 - variacion_velocidad, 1 + variacion_velocidad),  # speed_variation
			randf_range(1 - variacion_ancho, 1 + variacion_ancho)  # width_variation
		)
		if i < rayos_por_disparo - 1:
			await get_tree().create_timer(delay_entre_rayos).timeout
			
			
func disparar_abanico_cruzado():
	# Primer abanico
	for i in range(rayos_por_disparo):
		crear_rayo(
			Vector2((i - rayos_por_disparo/2.0) * separacion_rayos * 0.7, 0),  # position
			deg_to_rad(15),  # angle
			randf_range(0.9, 1.1)  # speed_variation
		)
		await get_tree().create_timer(delay_entre_rayos * 0.7).timeout
	
	# Segundo abanico invertido
	for i in range(rayos_por_disparo):
		crear_rayo(
			Vector2((rayos_por_disparo/2.0 - i) * separacion_rayos * 0.7, 0),  # position
			deg_to_rad(-15),  # angle
			randf_range(0.9, 1.1)  # speed_variation
		)
		await get_tree().create_timer(delay_entre_rayos * 0.7).timeout

func disparar_concentrado():
	var centro = rayos_por_disparo / 2.0
	for i in range(rayos_por_disparo):
		var distancia_al_centro = abs(i - centro)
		var offset = (i - centro) * separacion_rayos * (0.5 + distancia_al_centro * 0.1)
		crear_rayo(
			Vector2(offset, 0),  # position
			0.0,  # angle (asumiendo que es el tercer parámetro)
			1.2 - distancia_al_centro * 0.1,  # speed_variation
			1.0 + (centro - distancia_al_centro) * 0.1  # width_variation
		)
		await get_tree().create_timer(delay_entre_rayos * 0.8).timeout



func crear_rayo(position: Vector2, angle: float = 0.0, speed_variation: float = 1.0, width_variation: float = 1.0):
	var rayo = rayo_scene.instantiate()
	$Rayos.add_child(rayo)
	
	# Configurar posición y propiedades
	rayo.position = position
	rayo.global_position = rayo.global_position
	rayo.rotation = angle
	rayo.speed = rayo_speed * speed_variation
	rayo.width = rayo_width * width_variation
	
	# Efecto visual al crear
	animated_sprite.frame = 0
	animated_sprite.play("emitir")  # Animación corta de emisión
