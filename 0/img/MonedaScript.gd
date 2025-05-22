extends Node2D



func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		
		get_parent().monedas += 1
		print(str(get_parent().monedas))
		queue_free()
	pass # Replace with function body.
