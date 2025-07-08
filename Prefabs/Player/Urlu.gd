extends CharacterBody2D
#region ----------CONSTANTS & VAR DECLARATIONS----------
#movement constants
@export var GRAVITY: 			 int  =   80
@export var MAX_FALL_SPEED: 	 int  = 1700
@export var JUMP_FORCE: 		 int  = 1700
@export var WALL_JUMP_FORCE:	 int  = 1000
@export var MAX_SPEED:			 int  =  680
@export var ACCELERATION:		 int  =   80
@export var FRICTION:			float =    0.4
@export var AIR_FRICTION:		float =    0.05
@export var PLATFORM_CLIP_TIME: float =    0.1
const UP = Vector2(0,-1) #gravity
var motion: Vector2

#states variable declarations
var on_wall_right:	bool = false
var on_wall_left:	bool = false
var is_attacking:	bool = false
var is_hidden:		bool = false
var main_control_ref: Control = null


#sanity & moon mechanic constants
@export var MOON_PATH: NodePath
@onready var moon = get_node(MOON_PATH)
@export var GAMEOVER_PATH: NodePath
@onready var gameover = get_node(GAMEOVER_PATH)
@export var PAUSE_PATH: NodePath
@onready var pause_menu = get_node(PAUSE_PATH)
@export var MAX_SANITY: 			float = 360
@export var SANITY: 				float = 360
@export var SANITY_DRAIN_PASSIVE:	float = 0.2
@export var SANITY_DRAIN_MOON:		float = 1.0

#arrow variables
@export var ARROW_PATH: PackedScene
var cursor_angle: float
#@onready var arrow = get_node(ARROW_PATH)

#animation nodes
@onready var sprite 			= $Sprite
@onready var animationPlayer 	= $AnimationPlayer
@onready var sprite_overlay 	= $SpriteOverlay
@onready var sprite_underlay 	= $SpriteOverlay/SpriteUnderlay
@onready var bow_origin 		= $SpriteOverlay/BowOrigin
#collision nodes
@onready var collision_S		= $CollisionShape2D_S
@onready var collision_P		= $CollisionShape2D_P
@onready var platform_timer 	= $PlatformClipTimer
#multi
var chat_instance: Node
#endregion

func _input(event):
	#if event.is_action_pressed("ui_cancel"):
		#get_tree().quit()
		
	if event is InputEventMouseButton and event.is_action_pressed("attack"):
		if is_attacking == true:
			shoot()
			is_attacking = false
		elif is_on_floor():
			is_attacking = true
	elif event is InputEventMouseButton and event.is_action_pressed("attack_cancel"):
		is_attacking = false
	
	# Platform Clip Mechanic
	if event.is_action_pressed("down") and is_on_floor() and global_position.y < 800:
		collision_P.disabled = true
		collision_S.disabled = true
		platform_timer.start(PLATFORM_CLIP_TIME)

func _on_platform_clip_timer_timeout():
	collision_P.disabled = false
	collision_S.disabled = false

func _physics_process(_delta):
#region ---------------------SANITY---------------------
	# Constant passive damage
	take_damage(SANITY_DRAIN_PASSIVE)
	
	# If not under cover take moon damage every tick
	if !is_hidden:
		take_damage(SANITY_DRAIN_MOON * moon.LUM)

	# Check if dead
	if SANITY <= 0:
		die()
	#endregion

#region ------------------ATTACK STATE------------------
	if is_attacking:
		animationPlayer.play("attack")
		sprite_overlay.visible = true
		motion = Vector2.ZERO
		var relative_mouse_vector: Vector2 = (get_global_mouse_position() - bow_origin.global_position)
		#print(bow_origin.global_position, " ", global_position)
		handle_dynamic_attack_sprite(sprite.flip_h, relative_mouse_vector, -15, 60)
		return
	#endregion
	
#region --------------------MOVEMENT--------------------
	# Input
	var x_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	
	# Gravity
	if on_wall_right or on_wall_left:
		motion.y  = GRAVITY * 1.2
	else:
		motion.y += GRAVITY
	
	# Motion Clamping
	motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)
	motion.y = min  (motion.y,  MAX_FALL_SPEED)
	
	# X movement
	if x_input != 0:
		motion.x += x_input * ACCELERATION
		sprite.flip_h = x_input < 0
	elif is_on_floor():
		motion.x = lerp(motion.x, 0.0, FRICTION)
		
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
			motion.x =  WALL_JUMP_FORCE
			on_wall_left  = false #maybe redundant
		motion.x = lerp(motion.x, 0.0, AIR_FRICTION)
	
	# move and slide (movement collisions physics)
	velocity = motion
	move_and_slide()
	motion = velocity
#endregion

#region ---------------------STATES---------------------
	# onWall State Handler
	if is_on_floor() or !nextToWall():
		on_wall_right = false
		on_wall_left  = false
	elif onRightWall():
		on_wall_right = true
		motion.y = 0 # THIS BROKE IDK WHY BUT IT STILL WORKS FINE FOR GAMEPLAY
	elif onLeftWall():
		on_wall_left  = true
		motion.y = 0
		
	# Moon position tracking
	var moon_target_position = Vector2(moon.global_position.x-960,moon.global_position.y-global_position.y)
	$MoonRayTop.target_position    = moon_target_position
	$MoonRayBottom.target_position = moon_target_position
	
	# hidden state tracking
	if inShadow():
		is_hidden = true
	else:
		is_hidden = false
	#endregion

#region -------------------ANIMATIONS-------------------
	sprite_overlay.visible = false
	if is_on_floor():
		if x_input == 0:
			animationPlayer.play("Idle_Still")
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
		animationPlayer.play("Idle_Still")
		
	if nextToWall():
		if on_wall_right:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(true)
		if on_wall_left:
			animationPlayer.play("Hanging")
			sprite.set_flip_h(false)
	#endregion

#region ----------------STATE  Functions----------------
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
#endregion

#region ----------------Other  Functions----------------
func take_damage(damage: float):
	SANITY -= damage*2
	SANITY = clamp(SANITY, 0, MAX_SANITY) #keep value in range
#	$AnimationPlayer.play("hurt")
var not_sent=true
func die():
	print(get_tree().current_scene.scene_file_path)
	if get_tree().current_scene.scene_file_path == "res://Scenes/MultiPlayerPlay.tscn":
		not_sent=false
		chat_instance
		print("muerte enviada")
		get_tree().change_scene_to_file("res://Scenes/FinalPerder.tscn")
		
	else:
		pause_menu.call("disable_pause_menu")
		gameover.call("death") # Esto llama a la función de tu nodo "Gameover"
	
func apply_remote_event(data):
	match (data.subEvent):
		
		"death":
			chat_instance.on_opponent_defeated()
		"surrender":
			chat_instance.on_opponent_defeated()
	
func shoot():
	var arrow = ARROW_PATH.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = bow_origin.global_position
	
	arrow.set_direction(cursor_angle)

func handle_dynamic_attack_sprite(state: bool, direction: Vector2, min_rot_DEG: int, max_rot_DEG: int):
	var flip: int
	var angle: float = direction.angle()
	
	if !state:
		flip = 1
		# Limit angle range
		if angle < 0:
			angle = clamp(angle, deg_to_rad(-max_rot_DEG), 0)
		else:
			angle = clamp(angle, 0, deg_to_rad(-min_rot_DEG))
		cursor_angle = angle # for arrow
	else:
		flip = -1
		# Limit angle range
		if angle < 0:
			angle = clamp(angle, deg_to_rad(-180), deg_to_rad(max_rot_DEG-180))
		else:
			angle = clamp(angle, deg_to_rad(180+min_rot_DEG), deg_to_rad(180))
		cursor_angle = angle # for arrow
		angle += deg_to_rad(180-(max_rot_DEG-min_rot_DEG)/2)
	
	#print(rad_to_deg(angle))
	
	angle += deg_to_rad(20)
	sprite_overlay.rotation  =  angle
	sprite_underlay.rotation = -angle
	sprite_overlay.flip_h      = state # Correct Overlay Transformation 
	sprite_overlay.offset.x    = 10 * flip
	sprite_overlay.position.x  = 9  * flip
	sprite_underlay.flip_h     = state # Correct Underlay Transformation 
	sprite_underlay.offset.x   = 6  * flip
	sprite_underlay.position.x =-28 * flip

#endregion
