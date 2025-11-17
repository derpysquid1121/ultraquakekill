#Script to smooth the camera motion during roations on the X and Y axis so its not jittery.
extends Camera3D

#Effects the speed of the camera in its rotation
@export var speed := 44.0

func _physics_process(delta: float) -> void:
	#Declaring weight value that influences how fast the camera moves to the position of its parent
	var weight = clamp(delta * speed, 0.0, 1.0)
	
	#Transforming camera to its parent using interpolation
	global_transform = global_transform.interpolate_with(
		get_parent().global_transform,
		weight
	)
	
	#Updating postition of camera to the movement logic on MeshInstance
	global_position = get_parent().global_position
