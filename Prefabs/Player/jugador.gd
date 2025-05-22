extends CharacterBody2D

var is_hidden: bool = false
var health: int = 3



func _ready():
	pass
	
func _process(delta):
	check_shelter()
	pass

func _input(event):
	pass
	
func _init():
	pass

func check_shelter():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2.UP * 100  # Ajusta según el tamaño de tu personaje
	)
	var result = space_state.intersect_ray(query)
	is_hidden = result.has("collider") and result.collider.is_in_group("shelter")
	
	
	
func take_damage(amount: int):
	if !is_hidden:
		health -= amount
		$AnimationPlayer.play("hurt")
		if health <= 0:
			die()

func die():
	# Lógica de muerte
	queue_free()
	
	

var speed := 400
@onready var animated_sprite_2d = $AnimatedSprite2D

func _physics_process(delta):
	var inputVel = Input.get_axis("ui_left","ui_right")
	var saltar = Input.get_action_strength("ui_accept")
	velocity.x = inputVel * speed
	
	if saltar !=0 and is_on_floor():
		velocity.y =0
		velocity.y -= saltar * 2000
		
	
	if !is_on_floor():
		velocity.y += 100
	
	move_and_slide()
	if velocity.x !=0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("Iddle")
	
	if inputVel !=0:
		animated_sprite_2d.flip_h = inputVel <0
	print(inputVel)
