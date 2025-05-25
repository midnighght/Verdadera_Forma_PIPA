extends CharacterBody2D

var is_hidden: bool = false
var health: int = 3
@onready var health_bar = $TextureProgressBar
var max_health = 1000
var current_health = 1000


func _ready():
	health_bar.max_value = max_health
	health_bar.value = current_health
	pass
	

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	
func take_damage(amount: int):
	if !is_hidden:
		current_health -= amount
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
	#$MoonRay.target_position = (moon.global_position - global_position).normalized() * 1600
	var moon_target_position = Vector2(moon.global_position.x-960,moon.global_position.y-global_position.y)
	$MoonRayTop.target_position = moon_target_position
	$MoonRayBottom.target_position = moon_target_position
	
	#if inShadow():
		#isHidden = true
	#else:
		#isHidden = false
	
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
			sprite.set_flip_h(true)
		if onWallLeft:
			sprite.set_flip_h(false)
	
	
	# move and slide (movement collisions physics)
	velocity = motion
	move_and_slide()
	motion = velocity
	
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
		
#func inShadow():
	#return $MoonRayTop.is_colliding() and $MoonRayBottom.is_colliding()
