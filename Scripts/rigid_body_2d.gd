# Apple.gd
extends RigidBody2D

func _on_Area2D_body_entered(body):
	if body.name == "Floor":
		global_position = Vector2(randi() % 800, -50) # Reset to top at random x
		linear_velocity = Vector2.ZERO
