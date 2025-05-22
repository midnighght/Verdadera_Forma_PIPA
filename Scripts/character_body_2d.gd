extends CharacterBody2D

func _ready():
	pass
	
func _process(delta):
	pass

func _input(event):
	pass
	
func _init():
	pass
	
func _physics_process(delta):
	var inputVel = Input.get_axis("ui_left","ui_right")
	print(inputVel)
