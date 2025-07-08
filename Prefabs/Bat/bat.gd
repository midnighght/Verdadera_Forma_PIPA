extends CharacterBody2D

@export var MAX_SPEED: int = 120
@export var ACCELERATION: int = 20
@export var DIRECTION: int = 1
@export var PATROL_RANGE: int = 320
@export var DAMAGE_VALUE: int = 20

var motion: Vector2 = Vector2.ZERO
var switching: bool = false
var dying: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_area: Area2D = $HurtArea2D
@onready var death_timer 	= $DeathTimer
@onready var start_position: Vector2

var marker_right: Vector2
var marker_left: Vector2

signal death

func initialize():
	start_position = global_position
	marker_right 	= get_parent().get_node("MarkerRight").global_position
	marker_left 	= get_parent().get_node("MarkerLeft").global_position

func _ready():
	sprite.play("flying")
	sprite.flip_h = DIRECTION < 0
	hurt_area.body_entered.connect(_on_body_entered)
	hurt_area.area_entered.connect(_on_area_entered)
	death_timer.timeout.connect(_on_death)
	start_position = global_position

func _physics_process(delta):
	if switching or dying: return
	
	motion.x = clamp(motion.x,-MAX_SPEED,MAX_SPEED)
	motion.y = 0
	
	motion.x += DIRECTION * ACCELERATION
	
	# Change direction when outside range
	if DIRECTION > 0:
		if global_position.x > marker_right.x:
			switch_direction()
	elif DIRECTION < 0:
		if global_position.x < marker_left.x:
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

func _on_area_entered(area):
	area.get_parent().queue_free()
	emit_signal("death")
	sprite.play("switch")
	dying = true
	death_timer.start(0.5)

func _on_death():
	queue_free()

func _on_body_entered(body):
	pass
	#body.queue_free()
	#$AnimatedSprite2D.play("switch")
	#queue_free()
	#body.take_damage(DAMAGE_VALUE)
	#$Sprite2D.visible = true
