extends CharacterBody2D

#const GRAVITY = 60
#const MAX_FALL_SPEED = 1500
#const MAX_SPEED = 680
#const JUMP_FORCE = 1500
#const ACCELERATION = 80
#const FRICTION = 0.4
#const AIR_FRICTION = 0.05
#const WALL_JUMP_FORCE = 1000

#movement constants
const UP = Vector2(0,-1)
@export var GRAVITY: int = 60
@export var MAX_FALL_SPEED: int = 1500
@export var MAX_SPEED: int = 680
@export var JUMP_FORCE: int = 1500
@export var WALL_JUMP_FORCE: int = 1000
@export var ACCELERATION: int = 80
@export var FRICTION: float = 0.4
@export var AIR_FRICTION: float = 0.05
var motion = Vector2()
var on_wall_right = false
var on_wall_left = false

#sanity & moon mechanic constants
var is_hidden: bool = false
@export var MOON_PATH: NodePath
@onready var moon = get_node(MOON_PATH)
@export var MAX_SANITY: int
@export var SANITY: float
@export var SANITY_DRAIN_PASSIVE: float
@export var SANITY_DRAIN_MOON: float
 
#animation constants
@onready var sprite = $Sprite
@onready var animationPlayer = $AnimationPlayer

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _physics_process(_delta):
#--------------------MOVEMENT--------------------
	# Input
	var x_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Gravity
	if on_wall_right or on_wall_left:
		motion.y = GRAVITY * 1.2
	else:
		motion.y += GRAVITY
	
	# Motion Clamping
	motion.x = clamp(motion.x,-MAX_SPEED,MAX_SPEED)
	motion.y = min(motion.y,MAX_FALL_SPEED)
	
	# X movement
	if x_input != 0:
		motion.x += x_input * ACCELERATION
		sprite.flip_h = x_input < 0
	elif is_on_floor():
		motion.x = lerp(motion.x,0.0,FRICTION)
	
	# Jumping Mechanincs
	if Input.is_action_pressed("jump"):
		if is_on_floor():
			motion.y = -JUMP_FORCE
		elif on_wall_right:
			motion.y = -JUMP_FORCE
			motion.x = -WALL_JUMP_FORCE
			on_wall_right = false #maybe redundant
		elif on_wall_left:
			motion.y = -JUMP_FORCE
			motion.x = WALL_JUMP_FORCE
			on_wall_left = false #maybe redundant
		motion.x = lerp(motion.x,0.0,AIR_FRICTION)
	
	# move and slide (movement collisions physics)
	velocity = motion
	move_and_slide()
	motion = velocity

#--------------------STATES--------------------
	# onWall State Handler
	if is_on_floor() or !nextToWall():
		on_wall_right = false
		on_wall_left  = false
	elif onRightWall():
		on_wall_right = true
		motion.y = 0 # THIS BROKE IDK WHY BUT IT STILL WORKS FINE FOR GAMEPLAY
	elif onLeftWall():
		on_wall_left = true
		motion.y = 0
		
	# Moon position tracking
	var moon_target_position = Vector2(moon.global_position.x-960,moon.global_position.y-global_position.y)
	$MoonRayTop.target_position = moon_target_position
	$MoonRayBottom.target_position = moon_target_position
	
	# hidden state tracking
	if inShadow():
		is_hidden = true
	else:
		is_hidden = false
	
#--------------------SANITY--------------------
	# Constant passive damage
	take_damage(SANITY_DRAIN_PASSIVE)
	
	# If not under cover take moon damage every tick
	if !is_hidden:
		take_damage(SANITY_DRAIN_MOON)

	# Check if dead
	if SANITY <= 0:
		die()

	# Animations
	if is_on_floor():
		if x_input == 0:
			animationPlayer.play("Idle")
		else:
			animationPlayer.play("Runing")
	elif not nextToWall():
		if motion.y < -200:
			animationPlayer.play("Jumping")
		elif motion.y > -201 and motion.y < 201:
			animationPlayer.play("air")
		elif motion.y > 200:
			animationPlayer.play("Falling")
	else:
		animationPlayer.play("Idle")
		
	if nextToWall():
		if on_wall_right:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(true)
		if on_wall_left:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(false)
	
#--------------------Functions--------------------
func nextToWall():
	return $RightWall.is_colliding() or $LeftWall.is_colliding()
	
func onRightWall():
	if $RightWall.is_colliding():
		# if player not moving, walls wont be detected
		# AVOIDS WALL JUMP WHEN ON CORNERS
		if Input.get_action_strength("right") > 0 or motion.x > 150:
			return true
	else:
		return false
func onLeftWall():
	if $LeftWall.is_colliding():
		if Input.get_action_strength("left") > 0 or motion.x < -150:
			return true
	else:
		return false
		
func inShadow():
	return $MoonRayTop.is_colliding() and $MoonRayBottom.is_colliding()
	
func take_damage(damage: float):
	SANITY -= damage
	SANITY = clamp(SANITY, 0, MAX_SANITY) #keep value in range
#	$AnimationPlayer.play("hurt")

func die():
	# Lógica de muerte
	#queue_free()
	pass
