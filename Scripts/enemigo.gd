extends Node2D

@export var velocidad_maxima: float = 80.0
@export var suavizado_movimiento: float = 0.15
@export var cambio_direccion_tiempo: float = 2.0
@export var distancia_evasion: float = 60.0

var direccion_actual: Vector2 = Vector2.ZERO
var velocidad: Vector2 = Vector2.ZERO
var tiempo_para_cambio: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_deteccion: Area2D = $Area2D

func _ready():
	cambiar_direccion()
	tiempo_para_cambio = randf_range(1.0, cambio_direccion_tiempo)
	sprite.play("default")

func _physics_process(delta):
	# Temporizador y cambio de dirección
	tiempo_para_cambio -= delta
	if tiempo_para_cambio <= 0 or detectar_obstaculos():
		cambiar_direccion()
		tiempo_para_cambio = randf_range(cambio_direccion_tiempo * 0.7, cambio_direccion_tiempo * 1.3)
	
	# Movimiento suavizado
	var velocidad_deseada = direccion_actual * velocidad_maxima
	velocidad = velocidad.lerp(velocidad_deseada, suavizado_movimiento)
	position += velocidad * delta
	
	# Actualizar apariencia
	actualizar_apariencia()

func cambiar_direccion():
	var nueva_direccion = Vector2(
		randf_range(-1, 1),
		randf_range(-0.4, 0.4)
	).normalized()
	
	# Evitar direcciones muy verticales
	if abs(nueva_direccion.y) > 0.7:
		nueva_direccion.y *= 0.5
		nueva_direccion = nueva_direccion.normalized()
	
	direccion_actual = nueva_direccion

func detectar_obstaculos() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direccion_actual * distancia_evasion
	)
	query.exclude = [self]
	return space_state.intersect_ray(query).has("collider")


func actualizar_apariencia():
	# Voltear horizontalmente
	if velocidad.x != 0:
		sprite.flip_h = velocidad.x < 0
	
	# Pequeño efecto de "flotación" (opcional)
	
	
	# Mantener rotación vertica
	rotation = 0
	
	# Animaciones
	if velocidad.length() < 10:
		sprite.play("reposo")
	else:
		sprite.play("volar")
		

func _on_colision_jugador_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador"):
		# Reaccionar al jugador (huir o perseguir)
		var direccion_jugador = (body.global_position - global_position).normalized()
		direccion_actual = -direccion_jugador  # Para huir
		tiempo_para_cambio = cambio_direccion_tiempo * 0.5
