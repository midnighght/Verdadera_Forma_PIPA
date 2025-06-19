extends Node2D
var direction: Vector2
@export var speed = 3000
var despawn_timer: SceneTreeTimer

func set_direction(angle: float):
	rotation = angle
	direction = Vector2(cos(angle), sin(angle))

func _on_ready():
	despawn_timer = get_tree().create_timer(20.0)
	despawn_timer.timeout.connect(_on_despawn_timer_timeout)

func _physics_process(delta):
	if !$PlatformRay.is_colliding():
		position += direction * speed * delta
	else:
		trigger_quick_despawn()
		
func _on_despawn_timer_timeout() -> void:
	queue_free()

func _on_quick_despawn_timer_timeout() -> void:
	queue_free()
	
func trigger_quick_despawn():
	if despawn_timer and despawn_timer.is_connected("timeout", _on_despawn_timer_timeout):
		despawn_timer.disconnect("timeout", _on_despawn_timer_timeout)
	var quick_timer = get_tree().create_timer(10.0)
	quick_timer.timeout.connect(_on_quick_despawn_timer_timeout)
