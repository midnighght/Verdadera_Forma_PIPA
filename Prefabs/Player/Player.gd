extends CharacterBody2D

#const GRAVITY = 60
#const MAXFALLSPEED = 1500
#const MAXSPEED = 680
#const JUMPFORCE = 1500
#const ACCELERATION = 80
#const FRICTION = 0.4
#const AIR_FRICTION = 0.05
#const WALLJUMP = 1000

#movement constants
const UP = Vector2(0,-1)
@export var GRAVITY: int
@export var MAXFALLSPEED: int
@export var MAXSPEED: int
@export var JUMPFORCE: int
@export var WALLJUMP: int
@export var ACCELERATION: int
@export var FRICTION: float
@export var AIR_FRICTION: float
var motion = Vector2()
var onWallRight = false
var onWallLeft = false

#sanity & moon mechanic constants
var isHidden: bool = false
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
	if onWallRight or onWallLeft:
		motion.y = GRAVITY * 1.2
	else:
		motion.y += GRAVITY
	
	# Motion Clamping
	motion.x = clamp(motion.x,-MAXSPEED,MAXSPEED)
	motion.y = min(motion.y,MAXFALLSPEED)
	
	# X movement
	if x_input != 0:
		motion.x += x_input * ACCELERATION
		sprite.flip_h = x_input < 0
	elif is_on_floor():
		motion.x = lerp(motion.x,0.0,FRICTION)
	
	# Jumping Mechanincs
	if Input.is_action_pressed("jump"):
		if is_on_floor():
			motion.y = -JUMPFORCE
		elif onWallRight:
			motion.y = -JUMPFORCE
			motion.x = -WALLJUMP
			onWallRight = false #maybe redundant
		elif onWallLeft:
			motion.y = -JUMPFORCE
			motion.x = WALLJUMP
			onWallLeft = false #maybe redundant
		motion.x = lerp(motion.x,0.0,AIR_FRICTION)
	
	# move and slide (movement collisions physics)
	velocity = motion
	move_and_slide()
	motion = velocity

#--------------------STATES--------------------
	# onWall State Handler
	if is_on_floor() or !nextToWall():
		onWallRight = false
		onWallLeft  = false
	elif onRightWall():
		onWallRight = true
		motion.y = 0
	elif onLeftWall():
		onWallLeft = true
		motion.y = 0
		
	# Moon position tracking
	var moon_target_position = Vector2(moon.global_position.x-960,moon.global_position.y-global_position.y)
	$MoonRayTop.target_position = moon_target_position
	$MoonRayBottom.target_position = moon_target_position
	
	# hidden state tracking
	if inShadow():
		isHidden = true
	else:
		isHidden = false
	
#--------------------SANITY--------------------
	SANITY -= SANITY_DRAIN_PASSIVE
	if !isHidden:
		SANITY -= SANITY_DRAIN_MOON
	
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
		if onWallRight:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(true)
		if onWallLeft:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(false)
	
# Functions
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
