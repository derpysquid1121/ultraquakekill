extends Node3D
var step: float = 0.01
var max_step: float = 0.06
var swayPos:= Vector3()

func sway(mouse_motion: Vector2):
	var invert_mouse = mouse_motion * -step
	#invert_mouse.x = clampf(invert_mouse.x, -max_step, max_step)
	#invert_mouse.y = clampf(invert_mouse.y, -max_step, max_step)
	
	swayPos = Vector3(invert_mouse.x, invert_mouse.y, 0)
	
	return swayPos
	

func update_position_rotation(pos: Vector3) -> void:
	transform
	rotate_object_local(Vector3(0, 1, 0), pos.x*10)
	rotate_object_local(Vector3(1, 0, 0), pos.y*10)
	
