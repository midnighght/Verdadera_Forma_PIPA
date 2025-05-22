extends Area2D

var speed: float = 100
var width: float = 20
var damage: int = 1

func _ready():
	$CollisionShape2D.shape.size = Vector2(width, $AnimatedSprite2D.sprite_frames.get_frame_texture("caere", 0).get_height())
	$AnimatedSprite2D.play("caere")  # Animación del rayo cayendo
	scale.x = width / $AnimatedSprite2D.sprite_frames.get_frame_texture("caere", 0).get_width()

func _physics_process(delta):
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 100:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
	create_impact_effect()
	queue_free()

func create_impact_effect():
	var impacto = preload("res://Scenes/impactorayo.tscn").instantiate()
	get_parent().add_child(impacto)
	impacto.global_position = global_position
	impacto.play("explosion")
