extends CharacterBody2D

@export var MAX_SPEED: int = 120
@export var ACCELERATION: int = 20
@export var DIRECTION: int = 1
@export var PATROL_RANGE: int = 300
@export var DAMAGE_VALUE: int = 20

var motion: Vector2 = Vector2.ZERO
var switching: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_area: Area2D = $HurtArea2D
@onready var start_position: Vector2 = global_position



func _ready():
	$AnimatedSprite2D.play("flying")
	$AnimatedSprite2D.flip_h = DIRECTION < 0
	hurt_area.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if switching: return
	
	motion.x = clamp(motion.x,-MAX_SPEED,MAX_SPEED)
	motion.y = 0
	
	motion.x += DIRECTION * ACCELERATION
	
	# Change direction when outside range
	if DIRECTION > 0:
		if global_position.x - start_position.x > PATROL_RANGE:
			switch_direction()
	elif DIRECTION < 0:
		if global_position.x - start_position.x < -PATROL_RANGE:
			switch_direction()
	
	# move and slide (movement collisions physics)
	velocity = motion
	move_and_slide()
	motion = velocity

func switch_direction():
	switching = true
	sprite.play("switch")
	await sprite.animation_finished
	DIRECTION *= -1
	sprite.flip_h = DIRECTION < 0
	sprite.play("flying")
	switching = false

func _on_body_entered(body):
	body.take_damage(DAMAGE_VALUE)
	#$Sprite2D.visible = true
