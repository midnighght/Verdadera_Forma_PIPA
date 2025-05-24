extends CharacterBody2D

const Speed = 200
const Gravedad= 25
const Jump=-500
@export var jump2=-150

@export var salud=1000
@onready var anim= $AnimatedSprite2D
var inmune: bool=false
@onready var barra= $BarraDeVida

func _ready():
	
	barra.max_value=salud
func _process(delta):
	daño_ctrl()
	pass
func daño_ctrl():
	if inmune== true:
		if salud>0:
			salud-=1
			barra.value=salud
			inmune=false
		if salud<=0:
			get_tree().reload_current_scene()
	pass
func _physics_process(delta):
	var inputVel = Input.get_axis("ui_left","ui_right")
	var saltar = Input.get_action_strength("ui_accept")
	velocity.x = inputVel * Speed
	
	if saltar !=0 and is_on_floor():
		velocity.y =0
		velocity.y -= saltar * 2000

	
	if !is_on_floor():
		velocity.y += 100
	
	move_and_slide()
	if velocity.x !=0:
		anim.play("run")
	else:
		anim.play("Iddle")
	
	if inputVel !=0:
		AnimatedSprite2D.flip_h = inputVel <0
	print(inputVel)

	
